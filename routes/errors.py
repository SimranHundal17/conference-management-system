import mysql.connector
from flask import Blueprint, current_app, render_template
from werkzeug.exceptions import Forbidden, HTTPException, NotFound

errors_bp = Blueprint("errors", __name__)


@errors_bp.app_errorhandler(NotFound)
def not_found(error):
    return (
        render_template(
            "error.html",
            title="Page Not Found",
            status_code=404,
            heading="Page not found",
            message="The page you requested does not exist or has been moved.",
        ),
        404,
    )


@errors_bp.app_errorhandler(Forbidden)
def forbidden(error):
    return (
        render_template(
            "error.html",
            title="Access Denied",
            status_code=403,
            heading="Access denied",
            message="Your account does not have permission to access this page.",
        ),
        403,
    )


@errors_bp.app_errorhandler(mysql.connector.Error)
def database_error(error):
    current_app.logger.exception("Database error: %s", error)
    return (
        render_template(
            "error.html",
            title="Database Error",
            status_code=500,
            heading="Database error",
            message="The database could not complete the request. Please check the data and try again.",
        ),
        500,
    )


@errors_bp.app_errorhandler(Exception)
def unexpected_error(error):
    if isinstance(error, HTTPException):
        return error
    current_app.logger.exception("Unhandled application error: %s", error)
    return (
        render_template(
            "error.html",
            title="Application Error",
            status_code=500,
            heading="Application error",
            message="Something went wrong while processing the request.",
        ),
        500,
    )
