from functools import wraps

import mysql.connector
from flask import Blueprint, flash, redirect, render_template, request, session, url_for
from werkzeug.security import check_password_hash, generate_password_hash

from db import execute, fetch_one

auth_bp = Blueprint("auth", __name__)

# Local demonstration accounts; replace or disable before deployment.
DEMO_USERS = {
    "admin": {
        "password_hash": generate_password_hash("admin123"),
        "role": "admin",
        "display_name": "System Administrator",
    },
    "organizer": {
        "password_hash": generate_password_hash("organizer123"),
        "role": "organizer",
        "display_name": "Conference Organizer",
        "organizer_id": 1,
    },
    "student": {
        "password_hash": generate_password_hash("student123"),
        "role": "student",
        "display_name": "Student User",
        "student_id": 1,
    },
}


def _normalize_role(role_name):
    return (role_name or "").strip().lower()


def _load_database_user(username):
    return fetch_one(
        """
        SELECT ua.user_id, ua.username, ua.password_hash, ua.student_id, ua.organizer_id,
               ua.speaker_id, ua.account_locked, ur.role_name,
               COALESCE(CONCAT(s.first_name, ' ', s.last_name),
                        CONCAT(o.first_name, ' ', o.last_name),
                        CONCAT(sp.first_name, ' ', sp.last_name),
                        ua.username) AS display_name
        FROM UserAccount ua
        JOIN UserRole ur ON ua.role_id = ur.role_id
        LEFT JOIN Student s ON ua.student_id = s.student_id
        LEFT JOIN Organizer o ON ua.organizer_id = o.organizer_id
        LEFT JOIN Speaker sp ON ua.speaker_id = sp.speaker_id
        WHERE ua.username = %s
        """,
        (username,),
    )


def _record_login(user_id, status):
    if not user_id:
        return
    try:
        execute(
            """
            INSERT INTO LoginHistory (user_id, ip_address, device_info, login_status)
            VALUES (%s, %s, %s, %s)
            """,
            (user_id, request.remote_addr, request.user_agent.string[:255], status),
        )
        if status == "Success":
            execute("UPDATE UserAccount SET last_login = NOW() WHERE user_id = %s", (user_id,))
    except mysql.connector.Error:
        pass


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if "user" not in session:
            flash("Please log in to continue.", "warning")
            return redirect(url_for("auth.login"))
        return view(*args, **kwargs)

    return wrapped


def role_required(*roles):
    def decorator(view):
        @wraps(view)
        def wrapped(*args, **kwargs):
            user = session.get("user")
            if not user:
                flash("Please log in to continue.", "warning")
                return redirect(url_for("auth.login"))
            if user.get("role") not in roles:
                flash("You do not have permission to access that page.", "danger")
                return redirect(url_for("auth.dashboard"))
            return view(*args, **kwargs)

        return wrapped

    return decorator


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")
        db_user = _load_database_user(username)

        if db_user:
            role = _normalize_role(db_user["role_name"])
            if db_user["account_locked"]:
                _record_login(db_user["user_id"], "Failed")
                flash("This account is locked.", "danger")
                return render_template("login.html")

            if check_password_hash(db_user["password_hash"], password):
                session.clear()
                session["user"] = {
                    "user_id": db_user["user_id"],
                    "username": db_user["username"],
                    "role": role,
                    "display_name": db_user["display_name"],
                    "student_id": db_user["student_id"],
                    "organizer_id": db_user["organizer_id"],
                    "speaker_id": db_user["speaker_id"],
                }
                _record_login(db_user["user_id"], "Success")
                flash(f"Welcome back, {db_user['display_name']}.", "success")
                return redirect(url_for("auth.dashboard"))

            _record_login(db_user["user_id"], "Failed")

        user = DEMO_USERS.get(username)

        if user and check_password_hash(user["password_hash"], password):
            session.clear()
            session["user"] = {
                "username": username,
                "role": user["role"],
                "display_name": user["display_name"],
                "student_id": user.get("student_id"),
                "organizer_id": user.get("organizer_id"),
            }
            flash(f"Welcome back, {user['display_name']}.", "success")
            return redirect(url_for("auth.dashboard"))

        flash("Invalid username or password.", "danger")

    return render_template("login.html")


@auth_bp.route("/dashboard")
@login_required
def dashboard():
    role = session["user"]["role"]
    if role == "speaker":
        flash("Speaker profiles are managed by admins and organizers; no separate speaker login role is enabled.", "info")
        return redirect(url_for("auth.logout"))
    return redirect(url_for(f"{role}.dashboard"))


@auth_bp.route("/logout")
def logout():
    session.clear()
    flash("You have been logged out.", "info")
    return redirect(url_for("auth.login"))
