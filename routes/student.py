import mysql.connector
from flask import Blueprint, flash, redirect, render_template, request, session, url_for

from db import call_procedure, execute, fetch_all, fetch_one
from routes.auth import role_required

student_bp = Blueprint("student", __name__)


def current_student_id():
    return session["user"].get("student_id") or 1


def current_user_account_id():
    return session["user"].get("user_id") or 1


@student_bp.route("/dashboard")
@role_required("student")
def dashboard():
    student_id = current_student_id()
    stats = {
        "Total Events": fetch_one("SELECT COUNT(*) AS value FROM Event")["value"],
        "Registered Events": fetch_one(
            "SELECT COUNT(*) AS value FROM Registration WHERE student_id = %s", (student_id,)
        )["value"],
        "Certificates Earned": fetch_one(
            """
            SELECT COUNT(*) AS value
            FROM Certificate c
            JOIN Registration r ON c.registration_id = r.registration_id
            WHERE r.student_id = %s
            """,
            (student_id,),
        )["value"],
    }
    upcoming = fetch_all(
        """
        SELECT e.event_id, e.event_title, e.start_date, e.end_date, v.venue_name, e.registration_fee
        FROM Event e
        JOIN Venue v ON e.venue_id = v.venue_id
        ORDER BY e.event_id ASC
        LIMIT 6
        """
    )
    return render_template("student/dashboard.html", stats=stats, upcoming=upcoming)


@student_bp.route("/events")
@role_required("student")
def events():
    q = f"%{request.args.get('q', '').strip()}%"
    rows = fetch_all(
        """
        SELECT e.event_id, e.event_title, e.description, e.start_date, e.end_date,
               e.registration_deadline, e.max_capacity, e.registration_fee,
               c.category_name, v.venue_name, es.status_name,
               CASE WHEN r.registration_id IS NULL THEN 0 ELSE 1 END AS is_registered
        FROM Event e
        JOIN EventCategory c ON e.category_id = c.category_id
        JOIN Venue v ON e.venue_id = v.venue_id
        JOIN EventStatus es ON e.status_id = es.status_id
        LEFT JOIN Registration r
            ON r.event_id = e.event_id AND r.student_id = %s
        WHERE e.event_title LIKE %s OR c.category_name LIKE %s OR v.venue_name LIKE %s
        ORDER BY e.event_id ASC
        """,
        (current_student_id(), q, q, q),
    )
    return render_template("student/events.html", rows=rows, q=request.args.get("q", ""))


@student_bp.post("/events/<int:event_id>/register")
@role_required("student")
def register_event(event_id):
    try:
        call_procedure("RegisterStudentForEvent", [current_student_id(), event_id])
        flash("Registration completed successfully.", "success")
    except mysql.connector.Error as exc:
        if exc.errno == 1062:
            flash("You are already registered for this event.", "warning")
        else:
            flash(f"Could not register for event: {exc.msg}", "danger")
    return redirect(url_for("student.events"))


@student_bp.route("/registrations")
@role_required("student")
def registrations():
    rows = fetch_all(
        """
        SELECT r.registration_id, e.event_title, r.registration_date, rs.status_name,
               e.start_date, e.end_date
        FROM Registration r
        JOIN Event e ON r.event_id = e.event_id
        JOIN RegistrationStatus rs ON r.status_id = rs.status_id
        WHERE r.student_id = %s
        ORDER BY r.registration_id ASC
        """,
        (current_student_id(),),
    )
    return render_template("table.html", title="My Registrations", rows=rows)


@student_bp.route("/schedule")
@role_required("student")
def schedule():
    rows = fetch_all(
        """
        SELECT s.session_id, e.event_title, s.title, s.start_datetime, s.end_datetime,
               r.room_name, st.type_name
        FROM Session s
        JOIN Event e ON s.event_id = e.event_id
        JOIN Room r ON s.room_id = r.room_id
        JOIN SessionType st ON s.session_type_id = st.session_type_id
        JOIN Registration reg ON reg.event_id = e.event_id
        WHERE reg.student_id = %s
        ORDER BY s.session_id ASC
        """,
        (current_student_id(),),
    )
    return render_template("table.html", title="Session Schedule", rows=rows)


@student_bp.route("/certificates")
@role_required("student")
def certificates():
    rows = fetch_all(
        """
        SELECT c.certificate_id, e.event_title, c.certificate_code, c.issued_date,
               ct.template_name, c.certificate_file_path
        FROM Certificate c
        JOIN Registration r ON c.registration_id = r.registration_id
        JOIN Event e ON r.event_id = e.event_id
        JOIN CertificateTemplate ct ON c.template_id = ct.template_id
        WHERE r.student_id = %s
          AND e.end_date < CURDATE()
        ORDER BY c.certificate_id ASC
        """,
        (current_student_id(),),
    )
    return render_template("table.html", title="My Certificates", rows=rows)


@student_bp.route("/feedback", methods=["GET", "POST"])
@role_required("student")
def feedback():
    student_id = current_student_id()
    if request.method == "POST":
        action = request.form.get("action")
        try:
            if action == "event_feedback":
                eligible_event = fetch_one(
                    """
                    SELECT e.event_id
                    FROM Event e
                    JOIN Registration r ON r.event_id = e.event_id
                    WHERE r.student_id = %s
                      AND e.event_id = %s
                      AND e.end_date < CURDATE()
                    """,
                    (student_id, request.form["event_id"]),
                )
                if not eligible_event:
                    flash("Feedback can be submitted only after the event has ended.", "warning")
                    return redirect(url_for("student.feedback"))
                execute(
                    """
                    INSERT INTO Feedback (student_id, event_id, feedback_type_id, rating, comments)
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (
                        student_id,
                        request.form["event_id"],
                        request.form["feedback_type_id"],
                        request.form["rating"],
                        request.form.get("comments"),
                    ),
                )
                flash("Event feedback submitted.", "success")
            elif action == "session_feedback":
                eligible_session = fetch_one(
                    """
                    SELECT s.session_id
                    FROM Session s
                    JOIN Event e ON s.event_id = e.event_id
                    JOIN Registration r ON r.event_id = e.event_id
                    WHERE r.student_id = %s
                      AND s.session_id = %s
                      AND s.end_datetime < NOW()
                    """,
                    (student_id, request.form["session_id"]),
                )
                if not eligible_session:
                    flash("Session feedback can be submitted only after the session has ended.", "warning")
                    return redirect(url_for("student.feedback"))
                execute(
                    """
                    INSERT INTO SessionFeedback (session_id, student_id, rating, comments)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (
                        request.form["session_id"],
                        student_id,
                        request.form["rating"],
                        request.form.get("comments"),
                    ),
                )
                flash("Session feedback submitted.", "success")
            else:
                flash("Choose a valid feedback action.", "danger")
        except mysql.connector.Error as exc:
            flash(f"Could not submit feedback: {exc.msg}", "danger")
        return redirect(url_for("student.feedback"))

    events = fetch_all(
        """
        SELECT DISTINCT e.event_id, e.event_title
        FROM Event e
        JOIN Registration r ON r.event_id = e.event_id
        WHERE r.student_id = %s
          AND e.end_date < CURDATE()
        ORDER BY e.event_title ASC
        """,
        (student_id,),
    )
    sessions = fetch_all(
        """
        SELECT DISTINCT s.session_id, CONCAT(e.event_title, ' - ', s.title) AS label
        FROM Session s
        JOIN Event e ON s.event_id = e.event_id
        JOIN Registration r ON r.event_id = e.event_id
        WHERE r.student_id = %s
          AND s.end_datetime < NOW()
        ORDER BY label ASC
        """,
        (student_id,),
    )
    types = fetch_all("SELECT feedback_type_id, type_name FROM FeedbackType ORDER BY feedback_type_id ASC")
    event_rows = fetch_all(
        """
        SELECT f.feedback_id, e.event_title, ft.type_name, f.rating, f.comments, f.submitted_at
        FROM Feedback f
        JOIN Event e ON f.event_id = e.event_id
        JOIN FeedbackType ft ON f.feedback_type_id = ft.feedback_type_id
        WHERE f.student_id = %s
        ORDER BY f.feedback_id DESC
        """,
        (student_id,),
    )
    session_rows = fetch_all(
        """
        SELECT sf.session_feedback_id, s.title, sf.rating, sf.comments, sf.submitted_at
        FROM SessionFeedback sf
        JOIN Session s ON sf.session_id = s.session_id
        WHERE sf.student_id = %s
        ORDER BY sf.session_feedback_id DESC
        """,
        (student_id,),
    )
    return render_template(
        "student/feedback.html",
        events=events,
        sessions=sessions,
        types=types,
        event_rows=event_rows,
        session_rows=session_rows,
    )


@student_bp.post("/feedback/event/<int:feedback_id>/delete")
@role_required("student")
def delete_event_feedback(feedback_id):
    try:
        execute(
            "DELETE FROM Feedback WHERE feedback_id = %s AND student_id = %s",
            (feedback_id, current_student_id()),
        )
        flash("Event feedback deleted.", "success")
    except mysql.connector.Error as exc:
        flash(f"Could not delete feedback: {exc.msg}", "danger")
    return redirect(url_for("student.feedback"))


@student_bp.post("/feedback/session/<int:session_feedback_id>/delete")
@role_required("student")
def delete_session_feedback(session_feedback_id):
    try:
        execute(
            "DELETE FROM SessionFeedback WHERE session_feedback_id = %s AND student_id = %s",
            (session_feedback_id, current_student_id()),
        )
        flash("Session feedback deleted.", "success")
    except mysql.connector.Error as exc:
        flash(f"Could not delete session feedback: {exc.msg}", "danger")
    return redirect(url_for("student.feedback"))


@student_bp.route("/notifications")
@role_required("student")
def notifications():
    rows = fetch_all(
        """
        SELECT n.notification_id, nt.type_name, n.message, n.sent_at, n.is_read
        FROM Notification n
        JOIN NotificationType nt ON n.notification_type_id = nt.notification_type_id
        WHERE n.user_id = %s
        ORDER BY n.notification_id DESC
        """,
        (current_user_account_id(),),
    )
    return render_template("student/notifications.html", rows=rows)


@student_bp.post("/notifications/<int:notification_id>/delete")
@role_required("student")
def delete_notification(notification_id):
    try:
        execute(
            "DELETE FROM Notification WHERE notification_id = %s AND user_id = %s",
            (notification_id, current_user_account_id()),
        )
        flash("Notification deleted.", "success")
    except mysql.connector.Error as exc:
        flash(f"Could not delete notification: {exc.msg}", "danger")
    return redirect(url_for("student.notifications"))
