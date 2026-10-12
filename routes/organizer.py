import mysql.connector
from flask import Blueprint, flash, redirect, render_template, request, session, url_for

from db import execute, fetch_all, fetch_one
from routes.auth import role_required

organizer_bp = Blueprint("organizer", __name__)


def current_organizer_id():
    return session["user"].get("organizer_id") or 1


def event_options():
    return {
        "categories": fetch_all("SELECT category_id, category_name FROM EventCategory ORDER BY category_id ASC"),
        "venues": fetch_all("SELECT venue_id, venue_name FROM Venue ORDER BY venue_id ASC"),
        "statuses": fetch_all("SELECT status_id, status_name FROM EventStatus ORDER BY status_id ASC"),
    }


@organizer_bp.route("/dashboard")
@role_required("organizer")
def dashboard():
    organizer_id = current_organizer_id()
    stats = {
        "Total Events Managed": fetch_one(
            "SELECT COUNT(*) AS value FROM Event WHERE organizer_id = %s", (organizer_id,)
        )["value"],
        "Total Registrations": fetch_one(
            """
            SELECT COUNT(*) AS value
            FROM Registration r JOIN Event e ON r.event_id = e.event_id
            WHERE e.organizer_id = %s
            """,
            (organizer_id,),
        )["value"],
        "Total Sessions": fetch_one(
            """
            SELECT COUNT(*) AS value
            FROM Session s JOIN Event e ON s.event_id = e.event_id
            WHERE e.organizer_id = %s
            """,
            (organizer_id,),
        )["value"],
    }
    events = fetch_all(
        """
        SELECT e.event_id, e.event_title, e.start_date, e.end_date, es.status_name
        FROM Event e JOIN EventStatus es ON e.status_id = es.status_id
        WHERE e.organizer_id = %s
        ORDER BY e.event_id ASC
        LIMIT 8
        """,
        (organizer_id,),
    )
    return render_template("organizer/dashboard.html", stats=stats, events=events)


@organizer_bp.route("/events")
@role_required("organizer")
def events():
    rows = fetch_all(
        """
        SELECT e.event_id, e.event_title, e.start_date, e.end_date, e.max_capacity,
               e.registration_fee, c.category_name, v.venue_name, es.status_name
        FROM Event e
        JOIN EventCategory c ON e.category_id = c.category_id
        JOIN Venue v ON e.venue_id = v.venue_id
        JOIN EventStatus es ON e.status_id = es.status_id
        WHERE e.organizer_id = %s
        ORDER BY e.event_id ASC
        """,
        (current_organizer_id(),),
    )
    return render_template("organizer/events.html", rows=rows)


@organizer_bp.route("/events/new", methods=["GET", "POST"])
@role_required("organizer")
def create_event():
    if request.method == "POST":
        return save_event()
    return render_template("organizer/event_form.html", title="Create Event", event=None, **event_options())


@organizer_bp.route("/events/<int:event_id>/edit", methods=["GET", "POST"])
@role_required("organizer")
def edit_event(event_id):
    event = fetch_one("SELECT * FROM Event WHERE event_id = %s AND organizer_id = %s", (event_id, current_organizer_id()))
    if not event:
        flash("Event not found.", "warning")
        return redirect(url_for("organizer.events"))
    if request.method == "POST":
        return save_event(event_id)
    return render_template("organizer/event_form.html", title="Edit Event", event=event, **event_options())


def save_event(event_id=None):
    data = (
        request.form["category_id"],
        current_organizer_id(),
        request.form["venue_id"],
        request.form["status_id"],
        request.form["event_title"],
        request.form.get("description"),
        request.form["start_date"],
        request.form["end_date"],
        request.form.get("registration_deadline") or None,
        request.form["max_capacity"],
        request.form.get("registration_fee") or 0,
    )
    try:
        if event_id:
            execute(
                """
                UPDATE Event
                SET category_id=%s, organizer_id=%s, venue_id=%s, status_id=%s,
                    event_title=%s, description=%s, start_date=%s, end_date=%s,
                    registration_deadline=%s, max_capacity=%s, registration_fee=%s
                WHERE event_id=%s AND organizer_id=%s
                """,
                data + (event_id, current_organizer_id()),
            )
            flash("Event updated.", "success")
        else:
            execute(
                """
                INSERT INTO Event
                (category_id, organizer_id, venue_id, status_id, event_title, description,
                 start_date, end_date, registration_deadline, max_capacity, registration_fee)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                """,
                data,
            )
            flash("Event created.", "success")
    except mysql.connector.Error as exc:
        flash(f"Could not save event: {exc.msg}", "danger")
    return redirect(url_for("organizer.events"))


@organizer_bp.post("/events/<int:event_id>/delete")
@role_required("organizer")
def delete_event(event_id):
    try:
        execute("DELETE FROM Event WHERE event_id = %s AND organizer_id = %s", (event_id, current_organizer_id()))
        flash("Event deleted.", "success")
    except mysql.connector.Error as exc:
        flash(f"Could not delete event: {exc.msg}", "danger")
    return redirect(url_for("organizer.events"))


@organizer_bp.route("/registrations")
@role_required("organizer")
def registrations():
    rows = fetch_all(
        """
        SELECT r.registration_id, e.event_title, s.first_name, s.last_name, s.email,
               rs.status_name, r.registration_date
        FROM Registration r
        JOIN Event e ON r.event_id = e.event_id
        JOIN Student s ON r.student_id = s.student_id
        JOIN RegistrationStatus rs ON r.status_id = rs.status_id
        WHERE e.organizer_id = %s
        ORDER BY r.registration_id ASC
        """,
        (current_organizer_id(),),
    )
    statuses = fetch_all("SELECT status_id, status_name FROM RegistrationStatus ORDER BY status_id ASC")
    return render_template("organizer/registrations.html", rows=rows, statuses=statuses)


@organizer_bp.post("/registrations/<int:registration_id>/status")
@role_required("organizer")
def update_registration_status(registration_id):
    try:
        execute(
            """
            UPDATE Registration r
            JOIN Event e ON r.event_id = e.event_id
            SET r.status_id = %s
            WHERE r.registration_id = %s AND e.organizer_id = %s
            """,
            (request.form["status_id"], registration_id, current_organizer_id()),
        )
        flash("Registration status updated.", "success")
    except mysql.connector.Error as exc:
        flash(f"Could not update registration status: {exc.msg}", "danger")
    return redirect(url_for("organizer.registrations"))


@organizer_bp.route("/sessions", methods=["GET", "POST"])
@role_required("organizer")
def sessions():
    if request.method == "POST":
        try:
            execute(
                """
                INSERT INTO Session
                (event_id, room_id, session_type_id, title, description, start_datetime, end_datetime, max_participants)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
                """,
                (
                    request.form["event_id"],
                    request.form["room_id"],
                    request.form["session_type_id"],
                    request.form["title"],
                    request.form.get("description"),
                    request.form["start_datetime"],
                    request.form["end_datetime"],
                    request.form.get("max_participants") or None,
                ),
            )
            flash("Session created.", "success")
        except mysql.connector.Error as exc:
            flash(f"Could not create session: {exc.msg}", "danger")
        return redirect(url_for("organizer.sessions"))

    rows = fetch_all(
        """
        SELECT s.session_id, e.event_title, s.title, s.start_datetime, s.end_datetime,
               r.room_name, st.type_name
        FROM Session s
        JOIN Event e ON s.event_id = e.event_id
        JOIN Room r ON s.room_id = r.room_id
        JOIN SessionType st ON s.session_type_id = st.session_type_id
        WHERE e.organizer_id = %s
        ORDER BY s.session_id ASC
        """,
        (current_organizer_id(),),
    )
    options = {
        "events": fetch_all(
            "SELECT event_id, event_title FROM Event WHERE organizer_id = %s ORDER BY event_id ASC",
            (current_organizer_id(),),
        ),
        "rooms": fetch_all("SELECT room_id, room_name FROM Room ORDER BY room_id ASC"),
        "types": fetch_all("SELECT session_type_id, type_name FROM SessionType ORDER BY session_type_id ASC"),
    }
    return render_template("organizer/sessions.html", rows=rows, **options)


@organizer_bp.route("/session-operations", methods=["GET", "POST"])
@role_required("organizer")
def session_operations():
    organizer_id = current_organizer_id()
    if request.method == "POST":
        action = request.form.get("action")
        try:
            if action == "assign_speaker":
                execute(
                    """
                    INSERT INTO SessionSpeaker (session_id, speaker_id, speaker_role)
                    VALUES (%s, %s, %s)
                    """,
                    (request.form["session_id"], request.form["speaker_id"], request.form.get("speaker_role")),
                )
                flash("Speaker assigned to session.", "success")
            elif action == "add_material":
                execute(
                    """
                    INSERT INTO SessionMaterial (session_id, file_name, file_path)
                    VALUES (%s, %s, %s)
                    """,
                    (request.form["session_id"], request.form["file_name"], request.form["file_path"]),
                )
                flash("Session material added.", "success")
            elif action == "add_resource":
                execute(
                    """
                    INSERT INTO SessionResource (session_id, resource_title, resource_link, resource_type)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (
                        request.form["session_id"],
                        request.form["resource_title"],
                        request.form["resource_link"],
                        request.form["resource_type"],
                    ),
                )
                flash("Session resource added.", "success")
            elif action == "add_booking":
                execute(
                    """
                    INSERT INTO RoomBooking (
                        room_id, session_id, booking_date,
                        booking_start_time, booking_end_time, booking_purpose
                    )
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (
                        request.form["room_id"],
                        request.form["session_id"],
                        request.form["booking_date"],
                        request.form["booking_start_time"],
                        request.form["booking_end_time"],
                        request.form.get("booking_purpose"),
                    ),
                )
                flash("Room booking created.", "success")
            elif action == "add_announcement":
                execute(
                    """
                    INSERT INTO EventAnnouncement (event_id, title, message)
                    VALUES (%s, %s, %s)
                    """,
                    (request.form["event_id"], request.form["title"], request.form["message"]),
                )
                flash("Event announcement posted.", "success")
            else:
                flash("Choose a valid operation.", "danger")
        except mysql.connector.Error as exc:
            flash(f"Could not complete operation: {exc.msg}", "danger")
        return redirect(url_for("organizer.session_operations"))

    sessions = fetch_all(
        """
        SELECT s.session_id, CONCAT(e.event_title, ' - ', s.title) AS label, s.room_id, e.event_id
        FROM Session s
        JOIN Event e ON s.event_id = e.event_id
        WHERE e.organizer_id = %s
        ORDER BY label ASC
        """,
        (organizer_id,),
    )
    events = fetch_all(
        "SELECT event_id, event_title FROM Event WHERE organizer_id = %s ORDER BY event_title ASC",
        (organizer_id,),
    )
    rows = {
        "assignments": fetch_all(
            """
            SELECT ss.session_id, s.title AS session_title,
                   CONCAT(sp.first_name, ' ', sp.last_name) AS speaker_name, ss.speaker_role
            FROM SessionSpeaker ss
            JOIN Session s ON ss.session_id = s.session_id
            JOIN Event e ON s.event_id = e.event_id
            JOIN Speaker sp ON ss.speaker_id = sp.speaker_id
            WHERE e.organizer_id = %s
            ORDER BY s.session_id ASC
            """,
            (organizer_id,),
        ),
        "materials": fetch_all(
            """
            SELECT sm.material_id, s.title AS session_title, sm.file_name, sm.file_path, sm.uploaded_at
            FROM SessionMaterial sm
            JOIN Session s ON sm.session_id = s.session_id
            JOIN Event e ON s.event_id = e.event_id
            WHERE e.organizer_id = %s
            ORDER BY sm.material_id DESC
            """,
            (organizer_id,),
        ),
        "resources": fetch_all(
            """
            SELECT sr.resource_id, s.title AS session_title, sr.resource_title,
                   sr.resource_type, sr.resource_link, sr.added_at
            FROM SessionResource sr
            JOIN Session s ON sr.session_id = s.session_id
            JOIN Event e ON s.event_id = e.event_id
            WHERE e.organizer_id = %s
            ORDER BY sr.resource_id DESC
            """,
            (organizer_id,),
        ),
        "bookings": fetch_all(
            """
            SELECT rb.booking_id, s.title AS session_title, r.room_name, rb.booking_date,
                   rb.booking_start_time, rb.booking_end_time, rb.booking_purpose
            FROM RoomBooking rb
            JOIN Session s ON rb.session_id = s.session_id
            JOIN Event e ON s.event_id = e.event_id
            JOIN Room r ON rb.room_id = r.room_id
            WHERE e.organizer_id = %s
            ORDER BY rb.booking_id DESC
            """,
            (organizer_id,),
        ),
        "announcements": fetch_all(
            """
            SELECT ea.announcement_id, e.event_title, ea.title, ea.message, ea.created_at
            FROM EventAnnouncement ea
            JOIN Event e ON ea.event_id = e.event_id
            WHERE e.organizer_id = %s
            ORDER BY ea.announcement_id DESC
            """,
            (organizer_id,),
        ),
    }
    return render_template(
        "organizer/session_operations.html",
        sessions=sessions,
        events=events,
        speakers=fetch_all("SELECT speaker_id, CONCAT(first_name, ' ', last_name) AS name FROM Speaker ORDER BY name"),
        rooms=fetch_all("SELECT room_id, room_name FROM Room ORDER BY room_name ASC"),
        rows=rows,
    )


@organizer_bp.post("/sessions/<int:session_id>/delete")
@role_required("organizer")
def delete_session(session_id):
    try:
        execute(
            """
            DELETE s
            FROM Session s
            JOIN Event e ON s.event_id = e.event_id
            WHERE s.session_id = %s AND e.organizer_id = %s
            """,
            (session_id, current_organizer_id()),
        )
        flash("Session deleted.", "success")
    except mysql.connector.Error as exc:
        flash(f"Could not delete session: {exc.msg}", "danger")
    return redirect(url_for("organizer.sessions"))


@organizer_bp.route("/schedule")
@role_required("organizer")
def schedule():
    rows = fetch_all(
        """
        SELECT es.schedule_id, e.event_title, es.scheduled_date, es.start_time,
               es.end_time, es.schedule_notes
        FROM EventSchedule es
        JOIN Event e ON es.event_id = e.event_id
        WHERE e.organizer_id = %s
        ORDER BY es.schedule_id ASC
        """,
        (current_organizer_id(),),
    )
    return render_template("table.html", title="Manage Schedules", rows=rows)


@organizer_bp.route("/attendance")
@role_required("organizer")
def attendance():
    return render_template(
        "table.html",
        title="Attendance Summary",
        rows=fetch_all("SELECT * FROM AttendanceSummary ORDER BY session_id ASC"),
    )


@organizer_bp.route("/feedback")
@role_required("organizer")
def feedback():
    return render_template(
        "table.html",
        title="Session Feedback Summary",
        rows=fetch_all("SELECT * FROM SessionFeedbackSummary ORDER BY session_id ASC"),
    )


@organizer_bp.route("/reports")
@role_required("organizer")
def reports():
    return render_template(
        "table.html",
        title="Event Registration Summary",
        rows=fetch_all("SELECT * FROM EventRegistrationSummary ORDER BY event_id ASC"),
    )
