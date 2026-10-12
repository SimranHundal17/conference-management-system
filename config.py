import os


class Config:
    """Application settings loaded from environment variables."""

    SECRET_KEY = os.getenv("SECRET_KEY", "dev-only-change-me")
    MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
    MYSQL_PORT = int(os.getenv("MYSQL_PORT", "3306"))
    MYSQL_USER = os.getenv("MYSQL_USER", "root")
    MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
    MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "conference_management_system")
    MYSQL_POOL_NAME = "conference_pool"
    MYSQL_POOL_SIZE = 5
