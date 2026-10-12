from contextlib import contextmanager

import mysql.connector
from flask import current_app
from mysql.connector import pooling

_pool = None


def _get_pool():
    """Create one connection pool per Flask process."""
    global _pool
    if _pool is None:
        _pool = pooling.MySQLConnectionPool(
            pool_name=current_app.config["MYSQL_POOL_NAME"],
            pool_size=current_app.config["MYSQL_POOL_SIZE"],
            host=current_app.config["MYSQL_HOST"],
            port=current_app.config["MYSQL_PORT"],
            user=current_app.config["MYSQL_USER"],
            password=current_app.config["MYSQL_PASSWORD"],
            database=current_app.config["MYSQL_DATABASE"],
        )
    return _pool


@contextmanager
def get_connection():
    """Yield a pooled MySQL connection and always close it back to the pool."""
    conn = _get_pool().get_connection()
    try:
        yield conn
    finally:
        conn.close()


def fetch_all(query, params=None):
    with get_connection() as conn:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query, params or ())
        rows = cursor.fetchall()
        cursor.close()
        return rows


def fetch_one(query, params=None):
    with get_connection() as conn:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query, params or ())
        row = cursor.fetchone()
        cursor.close()
        return row


def execute(query, params=None):
    """Execute a write query with rollback on failure."""
    with get_connection() as conn:
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute(query, params or ())
            conn.commit()
            return cursor.lastrowid
        except mysql.connector.Error:
            conn.rollback()
            raise
        finally:
            cursor.close()


def call_procedure(name, args):
    """Call a stored procedure inside an explicit transaction."""
    with get_connection() as conn:
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.callproc(name, args)
            conn.commit()
        except mysql.connector.Error:
            conn.rollback()
            raise
        finally:
            cursor.close()
