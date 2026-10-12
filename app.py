from flask import Flask, redirect, url_for

from config import Config
from routes.admin import admin_bp
from routes.auth import auth_bp
from routes.errors import errors_bp
from routes.organizer import organizer_bp
from routes.student import student_bp


def create_app():
    """Application factory used by Flask and local development."""
    app = Flask(__name__)
    app.config.from_object(Config)

    app.register_blueprint(auth_bp)
    app.register_blueprint(errors_bp)
    app.register_blueprint(student_bp, url_prefix="/student")
    app.register_blueprint(organizer_bp, url_prefix="/organizer")
    app.register_blueprint(admin_bp, url_prefix="/admin")

    @app.route("/")
    def index():
        return redirect(url_for("auth.login"))

    return app


app = create_app()


if __name__ == "__main__":
    app.run(debug=True)
