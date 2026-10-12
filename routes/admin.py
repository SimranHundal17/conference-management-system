import mysql.connector
from flask import Blueprint, flash, redirect, render_template, request, session, url_for
from werkzeug.security import generate_password_hash

from db import call_procedure, execute, fetch_all, fetch_one, get_connection
from routes.auth import role_required

admin_bp = Blueprint("admin", __name__)

ENTITY_NOTES = {
    "AcademicProgram": "Degree programs offered by departments; students belong to one program.",
    "AttendanceCheckIn": "Event-level check-in records tied to registrations.",
    "CancellationRequest": "Student requests to cancel registrations.",
    "Certificate": "Issued completion certificates for registrations.",
    "CertificateTemplate": "Reusable certificate layout records.",
    "Department": "Academic or administrative departments that own programs and organizers.",
    "Event": "Main conference or event record.",
    "EventAgenda": "Ordered agenda items for an event.",
    "EventAnnouncement": "Messages published for an event.",
    "EventCategory": "Lookup table classifying events.",
    "EventSchedule": "Date and time blocks for events.",
    "EventStatus": "Lookup table for event lifecycle states.",
    "EventTag": "Reusable tags for event discovery.",
    "EventTagMapping": "Many-to-many bridge between events and tags.",
    "Feedback": "Student feedback for whole events.",
    "FeedbackType": "Lookup table for feedback categories.",
    "LoginHistory": "Audit trail of successful and failed database-account logins.",
    "Notification": "Messages sent to database user accounts.",
    "NotificationType": "Lookup table for notification categories.",
    "Organizer": "Staff or faculty members who manage events.",
    "Payment": "Payments attached to registrations.",
    "PaymentMethod": "Lookup table for payment methods.",
    "Refund": "Refund records connected to payments.",
    "Registration": "Student enrollment in an event.",
    "RegistrationStatus": "Lookup table for registration lifecycle states.",
    "Room": "Bookable rooms inside venues.",
    "RoomBooking": "Room reservations for sessions.",
    "RoomEquipment": "Equipment inventory for rooms.",
    "RoomType": "Lookup table for room categories.",
    "Session": "Talks, workshops, or schedule sessions inside events.",
    "SessionAttendance": "Student attendance at individual sessions.",
    "SessionFeedback": "Student ratings/comments for sessions.",
    "SessionMaterial": "Uploaded files for sessions.",
    "SessionResource": "External links or resources for sessions.",
    "SessionSpeaker": "Many-to-many bridge between sessions and speakers.",
    "SessionType": "Lookup table for session categories.",
    "Speaker": "People who present sessions.",
    "Student": "Students who register for events.",
    "StudentAddress": "Addresses connected to students.",
    "Ticket": "Tickets generated from registrations.",
    "TicketType": "Lookup table for ticket prices/types.",
    "UserAccount": "Login accounts linked to students, organizers, or speakers.",
    "UserRole": "Role lookup for database-backed accounts.",
    "Venue": "Physical locations containing rooms.",
    "Waitlist": "Students waiting for event capacity.",
}


def _database_objects():
    return fetch_all(
        """
        SELECT TABLE_NAME AS name, TABLE_TYPE AS object_type, TABLE_ROWS AS estimated_rows
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
        ORDER BY TABLE_TYPE, TABLE_NAME
        """
    )


def _find_database_object(name):
    normalized = name.lower()
    for item in _database_objects():
        if item["name"].lower() == normalized:
            return item
    return None


def _quote_identifier(name):
    return f"`{name.replace('`', '``')}`"


def _entity_note(name):
    for key, note in ENTITY_NOTES.items():
        if key.lower() == name.lower():
            return note
    return "Database view or reporting object."


def _object_columns(name):
    return fetch_all(
        """
        SELECT COLUMN_NAME AS column_name, COLUMN_TYPE AS column_type,
               IS_NULLABLE AS is_nullable, COLUMN_KEY AS column_key, EXTRA AS extra
        FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = %s
        ORDER BY ORDINAL_POSITION
        """,
        (name,),
    )


def _foreign_keys(name):
    return fetch_all(
        """
        SELECT COLUMN_NAME AS column_name, REFERENCED_TABLE_NAME AS referenced_table,
               REFERENCED_COLUMN_NAME AS referenced_column, CONSTRAINT_NAME AS constraint_name
        FROM information_schema.key_column_usage
        WHERE table_schema = DATABASE() AND table_name = %s AND referenced_table_name IS NOT NULL
        ORDER BY COLUMN_NAME
        """,
        (name,),
    )


def _referenced_by(name):
    return fetch_all(
        """
        SELECT TABLE_NAME AS table_name, COLUMN_NAME AS column_name,
               REFERENCED_COLUMN_NAME AS referenced_column, CONSTRAINT_NAME AS constraint_name
        FROM information_schema.key_column_usage
        WHERE table_schema = DATABASE() AND referenced_table_name = %s
        ORDER BY TABLE_NAME, COLUMN_NAME
        """,
        (name,),
    )


def _empty_to_none(value):
    value = (value or "").strip()
    return value or None


def _role_id(cursor, role_name):
    cursor.execute("SELECT role_id FROM UserRole WHERE LOWER(role_name) = LOWER(%s)", (role_name,))
    row = cursor.fetchone()
    if row:
        return row["role_id"]
    cursor.execute(
        "INSERT INTO UserRole (role_name, description) VALUES (%s, %s)",
        (role_name.title(), f"{role_name.title()} system access"),
    )
    return cursor.lastrowid


def _create_user_profile(form):
    role = form.get("role", "").strip().lower()
    username = form.get("username", "").strip()
    password = form.get("password", "")
    first_name = form.get("first_name", "").strip()
    last_name = form.get("last_name", "").strip()
    email = form.get("email", "").strip()

    if role not in {"student", "organizer", "admin"}:
        raise ValueError("Choose Student, Organizer, or Admin.")
    if not username or not password:
        raise ValueError("Username and password are required.")
    if role in {"student", "organizer"} and (not first_name or not last_name or not email):
        raise ValueError("First name, last name, and email are required for profile users.")

    with get_connection() as conn:
        cursor = conn.cursor(dictionary=True)
        try:
            role_id = _role_id(cursor, role)
            student_id = None
            organizer_id = None

            if role == "student":
                program_id = form.get("program_id")
                date_of_birth = form.get("date_of_birth")
                enrollment_year = form.get("enrollment_year")
                if not program_id or not date_of_birth or not enrollment_year:
                    raise ValueError("Program, date of birth, and enrollment year are required for students.")
                cursor.execute(
                    """
                    INSERT INTO Student (
                        program_id, first_name, last_name, email, phone_number,
                        date_of_birth, enrollment_year, account_status
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, 'Active')
                    """,
                    (
                        program_id,
                        first_name,
                        last_name,
                        email,
                        _empty_to_none(form.get("phone_number")),
                        date_of_birth,
                        enrollment_year,
                    ),
                )
                student_id = cursor.lastrowid

            if role == "organizer":
                department_id = form.get("department_id")
                if not department_id:
                    raise ValueError("Department is required for organizers.")
                cursor.execute(
                    """
                    INSERT INTO Organizer (
                        department_id, first_name, last_name, email, job_title, phone_number
                    )
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (
                        department_id,
                        first_name,
                        last_name,
                        email,
                        _empty_to_none(form.get("job_title")),
                        _empty_to_none(form.get("phone_number")),
                    ),
                )
                organizer_id = cursor.lastrowid

            cursor.execute(
                """
                INSERT INTO UserAccount (
                    student_id, organizer_id, speaker_id, role_id, username,
                    password_hash, account_locked
                )
                VALUES (%s, %s, NULL, %s, %s, %s, 0)
                """,
                (
                    student_id,
                    organizer_id,
                    role_id,
                    username,
                    generate_password_hash(password),
                ),
            )
            conn.commit()
            return cursor.lastrowid
        except Exception:
            conn.rollback()
            raise
        finally:
            cursor.close()


def _payment_transaction(form):
    action = form.get("action")
    with get_connection() as conn:
        cursor = conn.cursor(dictionary=True)
        try:
            if action == "create_payment":
                cursor.execute(
                    """
                    INSERT INTO Payment (
                        registration_id, payment_method_id, amount,
                        payment_status, transaction_reference
                    )
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (
                        form["registration_id"],
                        form["payment_method_id"],
                        form["amount"],
                        form.get("payment_status", "Pending"),
                        form.get("transaction_reference") or None,
                    ),
                )
                message = "Payment created."
            elif action == "update_payment":
                cursor.execute(
                    "UPDATE Payment SET payment_status = %s WHERE payment_id = %s",
                    (form["payment_status"], form["payment_id"]),
                )
                message = "Payment status updated."
            elif action == "create_refund":
                cursor.execute(
                    """
                    INSERT INTO Refund (payment_id, refund_amount, refund_reason)
                    VALUES (%s, %s, %s)
                    """,
                    (form["payment_id"], form["refund_amount"], form.get("refund_reason")),
                )
                cursor.execute(
                    "UPDATE Payment SET payment_status = 'Refunded' WHERE payment_id = %s",
                    (form["payment_id"],),
                )
                message = "Refund created and payment marked as refunded."
            else:
                raise ValueError("Choose a valid payment action.")
            conn.commit()
            return message
        except Exception:
            conn.rollback()
            raise
        finally:
            cursor.close()


@admin_bp.route("/dashboard")
@role_required("admin")
def dashboard():
    stats = {
        "Total Students": fetch_one("SELECT COUNT(*) AS value FROM Student")["value"],
        "Total Events": fetch_one("SELECT COUNT(*) AS value FROM Event")["value"],
        "Total Registrations": fetch_one("SELECT COUNT(*) AS value FROM Registration")["value"],
        "Total Revenue": fetch_one(
        "SELECT COALESCE(SUM(amount), 0) AS value FROM Payment WHERE payment_status = 'Completed'"
        )["value"],
    }
    return render_template("admin/dashboard.html", stats=stats)


@admin_bp.route("/user-accounts", methods=["GET", "POST"])
@role_required("admin")
def user_accounts():
    if request.method == "POST":
        try:
            user_id = _create_user_profile(request.form)
            flash(f"User account created with user_id {user_id}.", "success")
        except ValueError as exc:
            flash(str(exc), "danger")
        except mysql.connector.Error as exc:
            flash(f"Could not create user account: {exc.msg}", "danger")
        return redirect(url_for("admin.user_accounts"))

    rows = fetch_all(
        """
        SELECT ua.user_id, ua.username, ur.role_name, ua.account_locked, ua.last_login,
               COALESCE(CONCAT(s.first_name, ' ', s.last_name),
                        CONCAT(o.first_name, ' ', o.last_name),
                        CONCAT(sp.first_name, ' ', sp.last_name),
                        'Admin account') AS profile_name,
               s.email AS student_email, o.email AS organizer_email, sp.email AS speaker_email
        FROM UserAccount ua
        JOIN UserRole ur ON ua.role_id = ur.role_id
        LEFT JOIN Student s ON ua.student_id = s.student_id
        LEFT JOIN Organizer o ON ua.organizer_id = o.organizer_id
        LEFT JOIN Speaker sp ON ua.speaker_id = sp.speaker_id
        ORDER BY ua.user_id ASC
        """
    )
    programs = fetch_all(
        """
        SELECT program_id, CONCAT(program_name, ' (', degree_level, ')') AS label
        FROM AcademicProgram
        ORDER BY program_name ASC
        """
    )
    departments = fetch_all(
        "SELECT department_id, department_name FROM Department ORDER BY department_name ASC"
    )
    return render_template(
        "admin/user_accounts.html",
        rows=rows,
        programs=programs,
        departments=departments,
    )


@admin_bp.post("/user-accounts/<int:user_id>/lock")
@role_required("admin")
def toggle_user_account_lock(user_id):
    current_user_id = session.get("user", {}).get("user_id")
    if current_user_id == user_id:
        flash("You cannot lock your own account while logged in.", "warning")
        return redirect(url_for("admin.user_accounts"))

    account = fetch_one(
        "SELECT user_id, username, account_locked FROM UserAccount WHERE user_id = %s",
        (user_id,),
    )
    if not account:
        flash("User account not found.", "warning")
        return redirect(url_for("admin.user_accounts"))

    new_value = 0 if account["account_locked"] else 1
    execute(
        "UPDATE UserAccount SET account_locked = %s WHERE user_id = %s",
        (new_value, user_id),
    )
    state = "unlocked" if new_value == 0 else "locked"
    flash(f"Account {account['username']} has been {state}.", "success")
    return redirect(url_for("admin.user_accounts"))


@admin_bp.post("/user-accounts/<int:user_id>/delete")
@role_required("admin")
def delete_user_account(user_id):
    current_user_id = session.get("user", {}).get("user_id")
    if current_user_id == user_id:
        flash("You cannot delete your own account while logged in.", "warning")
        return redirect(url_for("admin.user_accounts"))

    account = fetch_one(
        "SELECT user_id, username FROM UserAccount WHERE user_id = %s",
        (user_id,),
    )
    if not account:
        flash("User account not found.", "warning")
        return redirect(url_for("admin.user_accounts"))

    try:
        execute("DELETE FROM UserAccount WHERE user_id = %s", (user_id,))
        flash(f"Account {account['username']} has been deleted.", "success")
    except mysql.connector.Error as exc:
        flash(f"Could not delete user account: {exc.msg}", "danger")
    return redirect(url_for("admin.user_accounts"))


@admin_bp.route("/students")
@role_required("admin")
def students():
    rows = fetch_all(
        """
        SELECT s.student_id, s.first_name, s.last_name, s.email, s.enrollment_year,
               s.account_status, ap.program_name
        FROM Student s JOIN AcademicProgram ap ON s.program_id = ap.program_id
        ORDER BY s.student_id ASC
        """
    )
    return render_template("table.html", title="All Students", rows=rows)


@admin_bp.route("/organizers")
@role_required("admin")
def organizers():
    rows = fetch_all(
        """
        SELECT o.organizer_id, o.first_name, o.last_name, o.email, o.job_title, d.department_name
        FROM Organizer o JOIN Department d ON o.department_id = d.department_id
        ORDER BY o.organizer_id ASC
        """
    )
    return render_template("table.html", title="All Organizers", rows=rows)


@admin_bp.route("/speakers", methods=["GET", "POST"])
@role_required("admin")
def speakers():
    if request.method == "POST":
        try:
            execute_speaker_write(request.form)
            flash("Speaker saved.", "success")
        except mysql.connector.Error as exc:
            flash(f"Could not save speaker: {exc.msg}", "danger")
        return redirect(url_for("admin.speakers"))

    rows = fetch_all(
        """
        SELECT speaker_id, first_name, last_name, email, organization_name,
               specialization, linkedin_url, created_at
        FROM Speaker
        ORDER BY speaker_id ASC
        """
    )
    return render_template("admin/speakers.html", rows=rows, speaker=None)


@admin_bp.route("/speakers/<int:speaker_id>/edit", methods=["GET", "POST"])
@role_required("admin")
def edit_speaker(speaker_id):
    speaker = fetch_one("SELECT * FROM Speaker WHERE speaker_id = %s", (speaker_id,))
    if not speaker:
        flash("Speaker not found.", "warning")
        return redirect(url_for("admin.speakers"))
    if request.method == "POST":
        try:
            execute_speaker_write(request.form, speaker_id)
            flash("Speaker updated.", "success")
        except mysql.connector.Error as exc:
            flash(f"Could not update speaker: {exc.msg}", "danger")
        return redirect(url_for("admin.speakers"))
    rows = fetch_all(
        """
        SELECT speaker_id, first_name, last_name, email, organization_name,
               specialization, linkedin_url, created_at
        FROM Speaker
        ORDER BY speaker_id ASC
        """
    )
    return render_template("admin/speakers.html", rows=rows, speaker=speaker)


@admin_bp.post("/speakers/<int:speaker_id>/delete")
@role_required("admin")
def delete_speaker(speaker_id):
    try:
        execute("DELETE FROM Speaker WHERE speaker_id = %s", (speaker_id,))
        flash("Speaker deleted.", "success")
    except mysql.connector.Error as exc:
        flash(f"Could not delete speaker: {exc.msg}", "danger")
    return redirect(url_for("admin.speakers"))


def execute_speaker_write(form, speaker_id=None):
    data = (
        form["first_name"],
        form["last_name"],
        form["email"],
        _empty_to_none(form.get("organization_name")),
        _empty_to_none(form.get("specialization")),
        _empty_to_none(form.get("biography")),
        _empty_to_none(form.get("linkedin_url")),
    )
    if speaker_id:
        execute(
            """
            UPDATE Speaker
            SET first_name=%s, last_name=%s, email=%s, organization_name=%s,
                specialization=%s, biography=%s, linkedin_url=%s
            WHERE speaker_id=%s
            """,
            data + (speaker_id,),
        )
    else:
        execute(
            """
            INSERT INTO Speaker (
                first_name, last_name, email, organization_name,
                specialization, biography, linkedin_url
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            data,
        )


@admin_bp.route("/events")
@role_required("admin")
def events():
    rows = fetch_all(
        """
        SELECT e.event_id, e.event_title, e.start_date, e.end_date, e.max_capacity,
               e.registration_fee, es.status_name
        FROM Event e JOIN EventStatus es ON e.status_id = es.status_id
        ORDER BY e.event_id ASC
        """
    )
    return render_template("table.html", title="All Events", rows=rows)


@admin_bp.route("/registrations")
@role_required("admin")
def registrations():
    rows = fetch_all(
        """
        SELECT r.registration_id, e.event_title, s.first_name, s.last_name,
               rs.status_name, r.registration_date
        FROM Registration r
        JOIN Event e ON r.event_id = e.event_id
        JOIN Student s ON r.student_id = s.student_id
        JOIN RegistrationStatus rs ON r.status_id = rs.status_id
        ORDER BY r.registration_id ASC
        """
    )
    statuses = fetch_all("SELECT status_id, status_name FROM RegistrationStatus ORDER BY status_id ASC")
    return render_template("admin/registrations.html", rows=rows, statuses=statuses)


@admin_bp.post("/registrations/<int:registration_id>/status")
@role_required("admin")
def update_registration_status(registration_id):
    try:
        execute(
            "UPDATE Registration SET status_id = %s WHERE registration_id = %s",
            (request.form["status_id"], registration_id),
        )
        flash("Registration status updated.", "success")
    except mysql.connector.Error as exc:
        flash(f"Could not update registration status: {exc.msg}", "danger")
    return redirect(url_for("admin.registrations"))


@admin_bp.route("/payments")
@role_required("admin")
def payments():
    rows = fetch_all(
        """
        SELECT p.payment_id, p.registration_id, CONCAT(s.first_name, ' ', s.last_name) AS student_name,
               e.event_title, p.amount, p.payment_status, p.payment_date,
               pm.method_name, p.transaction_reference
        FROM Payment p
        JOIN Registration r ON p.registration_id = r.registration_id
        JOIN Student s ON r.student_id = s.student_id
        JOIN Event e ON r.event_id = e.event_id
        JOIN PaymentMethod pm ON p.payment_method_id = pm.payment_method_id
        ORDER BY p.payment_id ASC
        """
    )
    registrations = fetch_all(
        """
        SELECT r.registration_id, CONCAT(s.first_name, ' ', s.last_name, ' - ', e.event_title) AS label
        FROM Registration r
        JOIN Student s ON r.student_id = s.student_id
        JOIN Event e ON r.event_id = e.event_id
        WHERE e.end_date < CURDATE()
        ORDER BY r.registration_id ASC
        """
    )
    methods = fetch_all("SELECT payment_method_id, method_name FROM PaymentMethod ORDER BY method_name ASC")
    refunds = fetch_all(
        """
        SELECT rf.refund_id, rf.payment_id, rf.refund_amount, rf.refund_reason, rf.refund_date
        FROM Refund rf
        ORDER BY rf.refund_id DESC
        """
    )
    return render_template(
        "admin/payments.html",
        rows=rows,
        registrations=registrations,
        methods=methods,
        refunds=refunds,
    )


@admin_bp.post("/payments/operations")
@role_required("admin")
def payment_operations():
    try:
        flash(_payment_transaction(request.form), "success")
    except ValueError as exc:
        flash(str(exc), "danger")
    except mysql.connector.Error as exc:
        flash(f"Could not complete payment operation: {exc.msg}", "danger")
    return redirect(url_for("admin.payments"))


@admin_bp.route("/database-features")
@role_required("admin")
def database_features():
    views = fetch_all(
        """
        SELECT TABLE_NAME AS view_name, VIEW_DEFINITION AS definition
        FROM information_schema.views
        WHERE table_schema = DATABASE()
        ORDER BY TABLE_NAME
        """
    )
    procedures = fetch_all(
        """
        SELECT ROUTINE_NAME AS procedure_name, ROUTINE_TYPE AS routine_type, CREATED AS created_at
        FROM information_schema.routines
        WHERE routine_schema = DATABASE()
        ORDER BY ROUTINE_NAME
        """
    )
    triggers = fetch_all(
        """
        SELECT TRIGGER_NAME AS trigger_name, EVENT_MANIPULATION AS event_name,
               EVENT_OBJECT_TABLE AS table_name, ACTION_TIMING AS timing
        FROM information_schema.triggers
        WHERE trigger_schema = DATABASE()
        ORDER BY TRIGGER_NAME
        """
    )
    indexes = fetch_all(
        """
        SELECT TABLE_NAME AS table_name, INDEX_NAME AS index_name,
               COLUMN_NAME AS column_name, NON_UNIQUE AS non_unique
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
        ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX
        """
    )
    grants = [
        {"database_user": "admin_user@localhost", "sql_role": "admin_role", "purpose": "Full database access"},
        {"database_user": "organizer_user@localhost", "sql_role": "organizer_role", "purpose": "Event/session operations"},
        {"database_user": "student_user@localhost", "sql_role": "student_role", "purpose": "Registration and participation"},
        {"database_user": "not created in 05_Roles.sql", "sql_role": "no speaker_role grant", "purpose": "Speaker is managed as session data by admins/organizers"},
    ]
    return render_template(
        "admin/database_features.html",
        views=views,
        procedures=procedures,
        triggers=triggers,
        indexes=indexes,
        grants=grants,
    )


@admin_bp.route("/payments-legacy")
@role_required("admin")
def payments_legacy():
    rows = fetch_all(
        """
        SELECT p.payment_id, p.registration_id, p.amount, p.payment_status,
               p.payment_date, pm.method_name, p.transaction_reference
        FROM Payment p JOIN PaymentMethod pm ON p.payment_method_id = pm.payment_method_id
        ORDER BY p.payment_id ASC
        """
    )
    return render_template("table.html", title="All Payments", rows=rows)


@admin_bp.route("/certificates", methods=["GET", "POST"])
@role_required("admin")
def certificates():
    if request.method == "POST":
        try:
            call_procedure("GenerateCertificate", [request.form["registration_id"], request.form["template_id"]])
            flash("Certificate generated.", "success")
        except mysql.connector.Error as exc:
            flash(f"Could not generate certificate: {exc.msg}", "danger")
        return redirect(url_for("admin.certificates"))

    rows = fetch_all("SELECT * FROM StudentCertificates ORDER BY student_id ASC")
    registrations = fetch_all(
        """
        SELECT r.registration_id, CONCAT(s.first_name, ' ', s.last_name, ' - ', e.event_title) AS label
        FROM Registration r
        JOIN Student s ON r.student_id = s.student_id
        JOIN Event e ON r.event_id = e.event_id
        ORDER BY r.registration_id ASC
        """
    )
    templates = fetch_all("SELECT template_id, template_name FROM CertificateTemplate ORDER BY template_id ASC")
    return render_template("admin/certificates.html", rows=rows, registrations=registrations, templates=templates)


@admin_bp.route("/reports/<name>")
@role_required("admin")
def reports(name):
    views = {
        "attendance": ("Attendance Summary", "AttendanceSummary", "session_id"),
        "registrations": ("Event Registration Summary", "EventRegistrationSummary", "event_id"),
        "revenue": ("Revenue Summary", "RevenueSummary", "event_id"),
        "feedback": ("Session Feedback Summary", "SessionFeedbackSummary", "session_id"),
        "certificates": ("Student Certificates", "StudentCertificates", "student_id"),
    }
    title, view_name, order_column = views.get(name, views["registrations"])
    return render_template("table.html", title=title, rows=fetch_all(f"SELECT * FROM {view_name} ORDER BY {order_column} ASC"))


@admin_bp.route("/database-statistics")
@role_required("admin")
def database_statistics():
    rows = fetch_all(
        """
        SELECT table_name, table_rows, data_length, index_length
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
        ORDER BY table_name ASC
        """
    )
    return render_template("table.html", title="Database Statistics", rows=rows)


@admin_bp.route("/schema")
@role_required("admin")
def schema():
    objects = _database_objects()
    for item in objects:
        item["note"] = _entity_note(item["name"])
    relationships = fetch_all(
        """
        SELECT TABLE_NAME AS child_table, COLUMN_NAME AS child_column,
               REFERENCED_TABLE_NAME AS parent_table, REFERENCED_COLUMN_NAME AS parent_column
        FROM information_schema.key_column_usage
        WHERE table_schema = DATABASE() AND referenced_table_name IS NOT NULL
        ORDER BY TABLE_NAME, COLUMN_NAME
        """
    )
    return render_template("admin/schema.html", title="Schema Explorer", objects=objects, relationships=relationships)


@admin_bp.route("/schema/<name>")
@role_required("admin")
def schema_object(name):
    item = _find_database_object(name)
    if not item:
        flash("Database object not found.", "warning")
        return redirect(url_for("admin.schema"))

    rows = fetch_all(f"SELECT * FROM {_quote_identifier(item['name'])} LIMIT 100")
    return render_template(
        "admin/schema_object.html",
        title=item["name"],
        item=item,
        note=_entity_note(item["name"]),
        columns=_object_columns(item["name"]),
        foreign_keys=_foreign_keys(item["name"]),
        referenced_by=_referenced_by(item["name"]),
        rows=rows,
    )
