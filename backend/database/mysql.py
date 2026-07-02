"""
Módulo de conexión a MySQL.

Este archivo centraliza la creación de conexiones para que
todo el backend utilice un único punto de acceso a la base
de datos.
"""

import os
import mysql.connector
from dotenv import load_dotenv

# Cargar variables del archivo .env
load_dotenv()

DB_CONFIG = {
    "host": os.getenv("MYSQL_HOST", "localhost"),
    "user": os.getenv("MYSQL_USER", "root"),
    "password": os.getenv("MYSQL_PASSWORD", ""),
    "database": os.getenv("MYSQL_DATABASE", "seed_races"),
    "port": int(os.getenv("MYSQL_PORT", 3306)),
}


def get_db_connection():
    """
    Devuelve una nueva conexión a MySQL.
    """

    return mysql.connector.connect(**DB_CONFIG)
    