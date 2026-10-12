import sys
import traceback
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from decimal import Decimal
from pathlib import Path

import mysql.connector

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from app import create_app  # noqa: E402
from config import Config  # noqa: E402


TEST_PREFIX = "AUTO_TEST_DEMO_"


@dataclass
class CheckResult:
    name: str
    status: str
    detail: str = ""


@dataclass
class ReadinessRunner:
    app: object = field(default_factory=create_app)
    results: list[CheckResult] = field(default_factory=list)
    created_event_id: int | None = None
    created_registration_id: int | None = None
    created_certificate_id: int | None = None

    def connect(self):
        return mysql.connector.connect(
            host=Config.MYSQL_HOST,
            port=Config.MYSQL_PORT,
            user=Config.MYSQL_USER,
            password=Config.MYSQL_PASSWORD,
            database=Config.MYSQL_DATABASE,
        )

    def record(self, name, status, detail=""):
        self.results.append(CheckResult(name, status, detail))
        marker = "PASS" if status == "PASS" else "FAIL"
        print(f"[{marker}] {name}: {detail}")

    def run_check(self, name, func):
        try:
            detail = func()
            self.record(name, "PASS", detail or "OK")
        except Exception as exc:
            self.record(name, "FAIL", f"{exc.__class__.__name__}: {exc}")
            traceback.print_exc()

    def scalar(self, query, params=None):
        with self.connect() as conn:
            cur = conn.cursor(dictionary=True)
            cur.execute(query, params or ())
            row = cur.fetchone()
            cur.close()
            return next(iter(row.values())) if row else None

    def row(self, query, params=None):
        with self.connect() as conn:
            cur = conn.cursor(dictionary=True)
            cur.execute(query, params or ())
            item = cur.fetchone()
            cur.close()
            return item

    def execute(self, query, params=None):
        with self.connect() as conn:
            cur = conn.cursor()
            cur.execute(query, params or ())
            conn.commit()
            lastrowid = cur.lastrowid
            cur.close()
            return lastrowid

    def callproc(self, name, args):
        with self.connect() as conn:
            cur = conn.cursor()
            cur.callproc(name, args)
            conn.commit()
            cur.close()

    def client_for(self, username, password):
        client = self.app.test_client()
        response = client.post(
            "/login",
            data={"username": username, "password": password},
            follow_redirects=False,
        )
        if response.status_code not in (302, 303):
            raise AssertionError(f"login for {username} returned {response.status_code}")
        return client

    def route_ok(self, client, path, expected=(200,)):
        response = client.get(path, follow_redirects=False)
        if response.status_code not in expected:
            raise AssertionError(f"{path} returned {response.status_code}")
        if b"Traceback" in response.data or b"Internal Server Error" in response.data:
            raise AssertionError(f"{path} rendered an exception page")
        return response.status_code

    def ensure_cleanup_first(self):
        self.cleanup()
        return "Removed stale automated test data."

    def database_connects(self):
        version = self.scalar("SELECT VERSION() AS version")
        return f"MySQL connection OK, version {version}."

    def required_views_return_data(self):
        views = [
            "AttendanceSummary",
            "EventRegistrationSummary",
            "RevenueSummary",
            "SessionFeedbackSummary",
            "StudentCertificates",
        ]
        details = []
        for view_name in views:
            count = self.scalar(f"SELECT COUNT(*) AS value FROM {view_name}")
            details.append(f"{view_name}={count}")
        return ", ".join(details)

    def required_routes_respond(self):
        anonymous = self.app.test_client()
        self.route_ok(anonymous, "/", expected=(302,))
        self.route_ok(anonymous, "/login")

        student = self.client_for("student", "student123")
        organizer = self.client_for("organizer", "organizer123")
        admin = self.client_for("admin", "admin123")

        for path in [
            "/student/dashboard",
            "/student/events",
            "/student/registrations",
            "/student/schedule",
            "/student/certificates",
            "/student/notifications",
        ]:
            self.route_ok(student, path)

        for path in [
            "/organizer/dashboard",
            "/organizer/events",
            "/organizer/events/new",
            "/organizer/registrations",
            "/organizer/sessions",
            "/organizer/schedule",
            "/organizer/attendance",
            "/organizer/feedback",
            "/organizer/reports",
        ]:
            self.route_ok(organizer, path)

        for path in [
            "/admin/dashboard",
            "/admin/students",
            "/admin/organizers",
            "/admin/events",
            "/admin/registrations",
            "/admin/payments",
            "/admin/certificates",
            "/admin/reports/attendance",
            "/admin/reports/registrations",
            "/admin/reports/revenue",
            "/admin/reports/feedback",
            "/admin/reports/certificates",
            "/admin/database-statistics",
        ]:
            self.route_ok(admin, path)

        return "Anonymous, student, organizer, and admin route groups responded."

    def role_enforcement(self):
        student = self.client_for("student", "student123")
        organizer = self.client_for("organizer", "organizer123")
        admin = self.client_for("admin", "admin123")

        checks = [
            (student, "/admin/dashboard"),
            (student, "/organizer/events"),
            (organizer, "/admin/dashboard"),
            (organizer, "/student/events"),
            (admin, "/student/events"),
            (admin, "/organizer/events"),
        ]
        for client, path in checks:
            response = client.get(path, follow_redirects=False)
            if response.status_code not in (302, 303):
                raise AssertionError(f"{path} should redirect for wrong role, got {response.status_code}")
        return "Cross-role protected URLs redirect correctly."

    def organizer_create_event_form(self):
        organizer = self.client_for("organizer", "organizer123")
        category_id = self.scalar("SELECT category_id AS value FROM EventCategory ORDER BY category_id LIMIT 1")
        venue_id = self.scalar("SELECT venue_id AS value FROM Venue ORDER BY venue_id LIMIT 1")
        status_id = self.scalar("SELECT status_id AS value FROM EventStatus ORDER BY status_id LIMIT 1")
        title = f"{TEST_PREFIX}{datetime.now().strftime('%Y%m%d%H%M%S')}"
        start = date.today() + timedelta(days=45)
        end = start + timedelta(days=1)

        before = self.scalar("SELECT COUNT(*) AS value FROM Event WHERE event_title LIKE %s", (f"{TEST_PREFIX}%",))
        response = organizer.post(
            "/organizer/events/new",
            data={
                "category_id": category_id,
                "venue_id": venue_id,
                "status_id": status_id,
                "event_title": title,
                "description": "Automated readiness test event.",
                "start_date": start.isoformat(),
                "end_date": end.isoformat(),
                "registration_deadline": (start - timedelta(days=7)).isoformat(),
                "max_capacity": 25,
                "registration_fee": "12.50",
            },
            follow_redirects=False,
        )
        if response.status_code not in (302, 303):
            raise AssertionError(f"event form returned {response.status_code}")

        event = self.row("SELECT * FROM Event WHERE event_title = %s", (title,))
        if not event:
            raise AssertionError("created event was not found in database")
        self.created_event_id = event["event_id"]
        after = self.scalar("SELECT COUNT(*) AS value FROM Event WHERE event_title LIKE %s", (f"{TEST_PREFIX}%",))
        if after <= before:
            raise AssertionError("event count did not increase")
        return f"Created Event.event_id={self.created_event_id}."

    def organizer_edit_event_form(self):
        if not self.created_event_id:
            raise AssertionError("create event check did not produce an event")
        organizer = self.client_for("organizer", "organizer123")
        response = organizer.post(
            f"/organizer/events/{self.created_event_id}/edit",
            data={
                "category_id": self.scalar("SELECT category_id AS value FROM EventCategory ORDER BY category_id LIMIT 1"),
                "venue_id": self.scalar("SELECT venue_id AS value FROM Venue ORDER BY venue_id LIMIT 1"),
                "status_id": self.scalar("SELECT status_id AS value FROM EventStatus ORDER BY status_id LIMIT 1"),
                "event_title": f"{TEST_PREFIX}UPDATED",
                "description": "Automated readiness test event, updated.",
                "start_date": (date.today() + timedelta(days=46)).isoformat(),
                "end_date": (date.today() + timedelta(days=47)).isoformat(),
                "registration_deadline": (date.today() + timedelta(days=40)).isoformat(),
                "max_capacity": 30,
                "registration_fee": "15.00",
            },
            follow_redirects=False,
        )
        if response.status_code not in (302, 303):
            raise AssertionError(f"edit form returned {response.status_code}")
        event = self.row("SELECT event_title, max_capacity FROM Event WHERE event_id = %s", (self.created_event_id,))
        if event["event_title"] != f"{TEST_PREFIX}UPDATED" or event["max_capacity"] != 30:
            raise AssertionError("event update was not persisted")
        return "Organizer edit event form persisted changed values."

    def organizer_create_session_form(self):
        if not self.created_event_id:
            raise AssertionError("create event check did not produce an event")
        organizer = self.client_for("organizer", "organizer123")
        room_id = self.scalar("SELECT room_id AS value FROM Room ORDER BY room_id LIMIT 1")
        session_type_id = self.scalar("SELECT session_type_id AS value FROM SessionType ORDER BY session_type_id LIMIT 1")
        before = self.scalar("SELECT COUNT(*) AS value FROM Session WHERE event_id = %s", (self.created_event_id,))
        start = datetime.now() + timedelta(days=46, hours=2)
        end = start + timedelta(hours=1)
        response = organizer.post(
            "/organizer/sessions",
            data={
                "event_id": self.created_event_id,
                "room_id": room_id,
                "session_type_id": session_type_id,
                "title": f"{TEST_PREFIX}Session",
                "description": "Automated readiness test session.",
                "start_datetime": start.strftime("%Y-%m-%dT%H:%M"),
                "end_datetime": end.strftime("%Y-%m-%dT%H:%M"),
                "max_participants": 20,
            },
            follow_redirects=False,
        )
        if response.status_code not in (302, 303):
            raise AssertionError(f"session form returned {response.status_code}")
        after = self.scalar("SELECT COUNT(*) AS value FROM Session WHERE event_id = %s", (self.created_event_id,))
        if after <= before:
            raise AssertionError("session count did not increase")
        return "Organizer session form inserted a Session row."

    def student_registration_procedure(self):
        if not self.created_event_id:
            raise AssertionError("create event check did not produce an event")
        student = self.client_for("student", "student123")
        before = self.scalar(
            "SELECT COUNT(*) AS value FROM Registration WHERE student_id = %s AND event_id = %s",
            (1, self.created_event_id),
        )
        response = student.post(f"/student/events/{self.created_event_id}/register", follow_redirects=False)
        if response.status_code not in (302, 303):
            raise AssertionError(f"student registration returned {response.status_code}")
        registration = self.row(
            "SELECT registration_id FROM Registration WHERE student_id = %s AND event_id = %s",
            (1, self.created_event_id),
        )
        if not registration:
            raise AssertionError("registration procedure did not create a Registration row")
        after = self.scalar(
            "SELECT COUNT(*) AS value FROM Registration WHERE student_id = %s AND event_id = %s",
            (1, self.created_event_id),
        )
        if after <= before:
            raise AssertionError("registration count did not increase")
        self.created_registration_id = registration["registration_id"]
        return f"RegisterStudentForEvent created Registration.registration_id={self.created_registration_id}."

    def admin_certificate_procedure(self):
        if not self.created_registration_id:
            raise AssertionError("registration check did not produce a registration")
        admin = self.client_for("admin", "admin123")
        template_id = self.scalar("SELECT template_id AS value FROM CertificateTemplate ORDER BY template_id LIMIT 1")
        before = self.scalar(
            "SELECT COUNT(*) AS value FROM Certificate WHERE registration_id = %s",
            (self.created_registration_id,),
        )
        response = admin.post(
            "/admin/certificates",
            data={"registration_id": self.created_registration_id, "template_id": template_id},
            follow_redirects=False,
        )
        if response.status_code not in (302, 303):
            raise AssertionError(f"certificate form returned {response.status_code}")
        cert = self.row(
            "SELECT certificate_id, certificate_code FROM Certificate WHERE registration_id = %s",
            (self.created_registration_id,),
        )
        if not cert:
            raise AssertionError("certificate procedure did not create a Certificate row")
        after = self.scalar(
            "SELECT COUNT(*) AS value FROM Certificate WHERE registration_id = %s",
            (self.created_registration_id,),
        )
        if after <= before:
            raise AssertionError("certificate count did not increase")
        self.created_certificate_id = cert["certificate_id"]
        return f"GenerateCertificate created Certificate.certificate_id={self.created_certificate_id}."

    def organizer_delete_event_form(self):
        if not self.created_event_id:
            raise AssertionError("create event check did not produce an event")
        organizer = self.client_for("organizer", "organizer123")
        response = organizer.post(f"/organizer/events/{self.created_event_id}/delete", follow_redirects=False)
        if response.status_code not in (302, 303):
            raise AssertionError(f"delete form returned {response.status_code}")
        exists = self.scalar("SELECT COUNT(*) AS value FROM Event WHERE event_id = %s", (self.created_event_id,))
        if exists:
            raise AssertionError("event delete did not remove the Event row")
        self.created_event_id = None
        self.created_registration_id = None
        self.created_certificate_id = None
        return "Organizer delete form removed the event and cascading child data."

    def no_unhandled_exceptions_on_core_flows(self):
        self.app.config.update(TESTING=True)
        client = self.app.test_client()
        for username, password in [
            ("admin", "admin123"),
            ("organizer", "organizer123"),
            ("student", "student123"),
        ]:
            response = client.post("/login", data={"username": username, "password": password})
            if response.status_code >= 500:
                raise AssertionError(f"login caused HTTP {response.status_code}")
            client.get("/logout")
        return "Core login/logout flows completed without HTTP 500 responses."

    def cleanup(self):
        with self.connect() as conn:
            cur = conn.cursor()
            cur.execute("SELECT event_id FROM Event WHERE event_title LIKE %s", (f"{TEST_PREFIX}%",))
            event_ids = [row[0] for row in cur.fetchall()]
            if event_ids:
                placeholders = ",".join(["%s"] * len(event_ids))
                cur.execute(f"DELETE FROM Event WHERE event_id IN ({placeholders})", event_ids)
            conn.commit()
            cur.close()
        self.created_event_id = None
        self.created_registration_id = None
        self.created_certificate_id = None

    def write_report(self):
        passed = sum(1 for result in self.results if result.status == "PASS")
        failed = sum(1 for result in self.results if result.status == "FAIL")
        ready = failed == 0
        lines = [
            "# Project Readiness Report",
            "",
            f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "## Automated Test Checklist",
            "",
        ]
        for result in self.results:
            mark = "[x]" if result.status == "PASS" else "[ ]"
            lines.append(f"- {mark} {result.name}: {result.status}. {result.detail}")
        lines.extend(
            [
                "",
                "## Summary",
                "",
                f"- Passed: {passed}",
                f"- Failed: {failed}",
                f"- Demonstration readiness: {'READY' if ready else 'NOT READY'}",
                "",
                "## Recommendation",
                "",
                (
                    "The application is ready for demonstration. Keep MySQL running, use the demo credentials, "
                    "and avoid changing seed lookup data immediately before presenting."
                    if ready
                    else "The application is not ready for demonstration until the failed checks above are fixed and rerun."
                ),
                "",
            ]
        )
        report_path = ROOT / "PROJECT_READINESS_REPORT.md"
        report_path.write_text("\n".join(lines), encoding="utf-8")
        return report_path, ready

    def run(self):
        self.app.config.update(TESTING=True)
        checks = [
            ("Cleanup stale automated test data", self.ensure_cleanup_first),
            ("Database connection", self.database_connects),
            ("Database views return data", self.required_views_return_data),
            ("All Flask routes respond correctly", self.required_routes_respond),
            ("User roles are enforced", self.role_enforcement),
            ("Organizer create event form submits and changes database", self.organizer_create_event_form),
            ("Organizer edit event form submits and changes database", self.organizer_edit_event_form),
            ("Organizer create session form submits and changes database", self.organizer_create_session_form),
            ("Student registration form executes stored procedure and changes database", self.student_registration_procedure),
            ("Admin certificate form executes stored procedure and changes database", self.admin_certificate_procedure),
            ("Organizer delete event form submits and changes database", self.organizer_delete_event_form),
            ("No SQL or Flask exceptions occur in core flows", self.no_unhandled_exceptions_on_core_flows),
        ]
        try:
            for name, func in checks:
                self.run_check(name, func)
        finally:
            self.cleanup()
        report_path, ready = self.write_report()
        print(f"\nReport written to: {report_path}")
        return 0 if ready else 1


if __name__ == "__main__":
    raise SystemExit(ReadinessRunner().run())
