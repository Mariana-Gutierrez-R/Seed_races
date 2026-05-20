from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from werkzeug.security import generate_password_hash, check_password_hash
import mysql.connector
import os
import re
import secrets
import hashlib
from datetime import datetime, timedelta

# ================== LOAD ENV VARIABLES ==================
load_dotenv()

# ================== APP ==================
app = Flask(__name__)
CORS(app)

# ================== CONFIG ==================
TOKEN_HOURS = 8


# ================== DB ==================
def get_db_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME"),
        autocommit=False,
        connection_timeout=5,
    )


# ================== HELPERS ==================
def validar_correo(correo):
    if not correo:
        return False

    patron = r"^[\w\.-]+@[\w\.-]+\.\w+$"
    return re.match(patron, correo) is not None


def validar_password(password):
    if not password or len(password) < 8:
        return False, "La contraseña debe tener mínimo 8 caracteres"

    if not re.search(r"[A-Z]", password):
        return False, "La contraseña debe tener al menos una mayúscula"

    if not re.search(r"[a-z]", password):
        return False, "La contraseña debe tener al menos una minúscula"

    if not re.search(r"[0-9]", password):
        return False, "La contraseña debe tener al menos un número"

    return True, "Contraseña válida"


def hash_token(token):
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


# ================== ROUTES ==================
@app.get("/auth/health")
def health():
    return jsonify({"ok": True, "servicio": "auth"})


@app.post("/auth/registro")
def registrar_usuario():
    data = request.get_json(force=False, silent=True) or {}

    nombre_usuario = (data.get("nombre_usuario") or "").strip()
    correo = (data.get("correo" ) or "").strip().lower()
    password = data.get("password") or ""

    if not nombre_usuario:
        return jsonify({"error": "El nombre de usuario es obligatorio"}), 400

    if not validar_correo(correo):
        return jsonify({"error": "El correo no tiene un formato válido"}), 400

    password_ok, mensaje_password = validar_password(password)

    if not password_ok:
        return jsonify({"error": mensaje_password}), 400

    password_hash = generate_password_hash(password)

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        cur.execute("""
            SELECT id_usuario
            FROM usuario
            WHERE correo = %s
            LIMIT 1
        """, (correo,))

        existe = cur.fetchone()

        if existe:
            return jsonify({"error": "El correo ya está registrado"}), 409

        cur.execute("""
            INSERT INTO usuario (
                nombre_usuario,
                correo,
                password_hash
            )
            VALUES (%s, %s, %s)
        """, (
            nombre_usuario,
            correo,
            password_hash,
        ))

        conn.commit()

        return jsonify({
            "mensaje": "Usuario registrado correctamente",
            "id_usuario": cur.lastrowid,
            "nombre_usuario": nombre_usuario,
            "correo": correo,
        }), 201

    finally:
        cur.close()
        conn.close()


@app.post("/auth/login")
def iniciar_sesion():
    data = request.get_json(force=False, silent=True) or {}

    correo = (data.get("correo") or "").strip().lower()
    password = data.get("password") or ""

    if not validar_correo(correo):
        return jsonify({"error": "Correo o contraseña inválidos"}), 401

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        cur.execute("""
            SELECT
                id_usuario,
                nombre_usuario,
                correo,
                password_hash,
                activo
            FROM usuario
            WHERE correo = %s
            LIMIT 1
        """, (correo,))

        usuario = cur.fetchone()

        if not usuario:
            return jsonify({"error": "Correo o contraseña inválidos"}), 401

        if not usuario["activo"]:
            return jsonify({"error": "Usuario inactivo"}), 403

        if not check_password_hash(usuario["password_hash"], password):
            return jsonify({"error": "Correo o contraseña inválidos"}), 401

        token = secrets.token_urlsafe(48)
        token_hash = hash_token(token)
        fecha_expiracion = datetime.now() + timedelta(hours=TOKEN_HOURS)

        cur.execute("""
            INSERT INTO sesion_usuario (
                id_usuario,
                token_hash,
                fecha_expiracion,
                activa
            )
            VALUES (%s, %s, %s, TRUE)
        """, (
            usuario["id_usuario"],
            token_hash,
            fecha_expiracion,
        ))

        conn.commit()

        return jsonify({
            "mensaje": "Inicio de sesión correcto",
            "token": token,
            "expira_en_horas": TOKEN_HOURS,
            "usuario": {
                "id_usuario": usuario["id_usuario"],
                "nombre_usuario": usuario["nombre_usuario"],
                "correo": usuario["correo"],
            }
        }), 200

    finally:
        cur.close()
        conn.close()


@app.post("/auth/logout")
def cerrar_sesion():
    data = request.get_json(force=False, silent=True) or {}
    token = data.get("token") or ""

    if not token:
        return jsonify({"error": "Token requerido"}), 400

    token_hash = hash_token(token)

    conn = get_db_connection()
    cur = conn.cursor(buffered=True)

    try:
        cur.execute("""
            UPDATE sesion_usuario
            SET activa = FALSE
            WHERE token_hash = %s
        """, (token_hash,))

        conn.commit()

        return jsonify({"mensaje": "Sesión cerrada correctamente"}), 200

    finally:
        cur.close()
        conn.close()


@app.post("/auth/validar-token")
def validar_token():
    data = request.get_json(force=False, silent=True) or {}
    token = data.get("token") or ""

    if not token:
        return jsonify({"valido": False}), 401

    token_hash = hash_token(token)

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        cur.execute("""
            SELECT
                su.id_sesion_usuario,
                su.id_usuario,
                su.fecha_expiracion,
                su.activa,
                u.nombre_usuario,
                u.correo
            FROM sesion_usuario su
            INNER JOIN usuario u ON su.id_usuario = u.id_usuario
            WHERE su.token_hash = %s
            LIMIT 1
        """, (token_hash,))

        sesion = cur.fetchone()

        if not sesion:
            return jsonify({"valido": False}), 401

        if not sesion["activa"]:
            return jsonify({"valido": False}), 401

        if sesion["fecha_expiracion"] < datetime.now():
            return jsonify({"valido": False, "error": "Token expirado"}), 401

        return jsonify({
            "valido": True,
            "usuario": {
                "id_usuario": sesion["id_usuario"],
                "nombre_usuario": sesion["nombre_usuario"],
                "correo": sesion["correo"],
            }
        }), 200

    finally:
        cur.close()
        conn.close()


# ================== RUN ==================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8001, debug=True, threaded=True)
    