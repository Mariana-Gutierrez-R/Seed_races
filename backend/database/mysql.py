"""
Módulo de conexión a MySQL.

"""

import os
import mysql.connector
from dotenv import load_dotenv

# Cargar variables del archivo .env
load_dotenv()


def _env(*names, default=None):
    """Devuelve la primera variable de entorno existente y no vacía."""
    for name in names:
        value = os.getenv(name)
        if value not in (None, ""):
            return value
    return default


DB_CONFIG = {
    "host": _env("MYSQL_HOST", "DB_HOST", default="localhost"),
    "user": _env("MYSQL_USER", "DB_USER", default="root"),
    "password": _env("MYSQL_PASSWORD", "DB_PASSWORD", default=""),
    "database": _env("MYSQL_DATABASE", "DB_NAME", default="seed_races"),
    "port": int(_env("MYSQL_PORT", "DB_PORT", default="3306")),
    "autocommit": False,
    "connection_timeout": 5,
}


def get_db_connection():
    """Devuelve una nueva conexión a MySQL."""
    return mysql.connector.connect(**DB_CONFIG)
