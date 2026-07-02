from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from werkzeug.security import generate_password_hash, check_password_hash
from database.mysql import get_db_connection
from services.profile_service import (
    asegurar_perfil_usuario,
    serializar_perfil_usuario,
    serializar_burbuja_usuario,
    obtener_opciones_personalizacion,
    actualizar_avatar_usuario,
    actualizar_puntero_usuario,
)
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
PHONE_CODE_MINUTES = 10



# ================== HELPERS ==================
def validar_correo(correo):
    if not correo:
        return False
    patron = r"^[\w\.-]+@[\w\.-]+\.\w+$"
    return re.match(patron, correo) is not None


def validar_telefono(telefono):
    if not telefono:
        return False
    patron = r"^\+?[0-9]{7,15}$"
    return re.match(patron, telefono) is not None


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


def generar_password_temporal():
    return generate_password_hash(secrets.token_urlsafe(32))


def crear_token_sesion(cur, id_usuario):
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
        id_usuario,
        token_hash,
        fecha_expiracion,
    ))

    return token


def respuesta_login(token, usuario):
    return {
        "mensaje": "Inicio de sesión correcto",
        "token": token,
        "expira_en_horas": TOKEN_HOURS,
        "usuario": {
            "id_usuario": usuario["id_usuario"],
            "nombre_usuario": usuario["nombre_usuario"],
            "correo": usuario["correo"],
            "telefono": usuario.get("telefono"),
            "foto_perfil": usuario.get("foto_perfil"),
            "proveedor_login": usuario.get("proveedor_login"),
        }
    }


def buscar_usuario_por_correo(cur, correo):
    cur.execute("""
        SELECT
            id_usuario,
            nombre_usuario,
            correo,
            telefono,
            foto_perfil,
            proveedor_login,
            id_externo,
            password_hash,
            activo
        FROM usuario
        WHERE correo = %s
        LIMIT 1
    """, (correo,))
    return cur.fetchone()


def buscar_usuario_por_proveedor(cur, proveedor_login, id_externo):
    cur.execute("""
        SELECT
            id_usuario,
            nombre_usuario,
            correo,
            telefono,
            foto_perfil,
            proveedor_login,
            id_externo,
            password_hash,
            activo
        FROM usuario
        WHERE proveedor_login = %s
          AND id_externo = %s
        LIMIT 1
    """, (proveedor_login, id_externo))
    return cur.fetchone()


def buscar_usuario_por_telefono(cur, telefono):
    cur.execute("""
        SELECT
            id_usuario,
            nombre_usuario,
            correo,
            telefono,
            foto_perfil,
            proveedor_login,
            id_externo,
            password_hash,
            activo
        FROM usuario
        WHERE telefono = %s
        LIMIT 1
    """, (telefono,))
    return cur.fetchone()


def obtener_usuario_por_id(cur, id_usuario):
    cur.execute("""
        SELECT
            id_usuario,
            nombre_usuario,
            correo,
            telefono,
            foto_perfil,
            proveedor_login,
            id_externo,
            activo
        FROM usuario
        WHERE id_usuario = %s
        LIMIT 1
    """, (id_usuario,))
    return cur.fetchone()




# ================== ROUTES ==================
@app.get("/auth/health")
def health():
    return jsonify({"ok": True, "servicio": "auth"})


@app.post("/auth/registro")
def registrar_usuario():
    data = request.get_json(force=False, silent=True) or {}

    nombre_usuario = (data.get("nombre_usuario") or "").strip()
    correo = (data.get("correo") or "").strip().lower()
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
        existe = buscar_usuario_por_correo(cur, correo)

        if existe:
            return jsonify({"error": "El correo ya está registrado"}), 409

        cur.execute("""
            INSERT INTO usuario (
                nombre_usuario,
                correo,
                proveedor_login,
                password_hash
            )
            VALUES (%s, %s, 'local', %s)
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
            "proveedor_login": "local",
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
        usuario = buscar_usuario_por_correo(cur, correo)

        if not usuario:
            return jsonify({"error": "Correo o contraseña inválidos"}), 401

        if not usuario["activo"]:
            return jsonify({"error": "Usuario inactivo"}), 403

        if usuario["proveedor_login"] != "local":
            return jsonify({
                "error": f"Este usuario debe iniciar sesión con {usuario['proveedor_login']}"
            }), 403

        if not check_password_hash(usuario["password_hash"], password):
            return jsonify({"error": "Correo o contraseña inválidos"}), 401

        token = crear_token_sesion(cur, usuario["id_usuario"])
        conn.commit()

        return jsonify(respuesta_login(token, usuario)), 200

    finally:
        cur.close()
        conn.close()


@app.post("/auth/google-login")
def google_login():
    data = request.get_json(force=False, silent=True) or {}

    id_externo = (data.get("id_externo") or "").strip()
    correo = (data.get("correo") or "").strip().lower()
    nombre_usuario = (data.get("nombre_usuario") or "").strip()
    foto_perfil = (data.get("foto_perfil") or "").strip() or None

    if not id_externo:
        return jsonify({"error": "id_externo de Google requerido"}), 400

    if not validar_correo(correo):
        return jsonify({"error": "Correo de Google inválido"}), 400

    if not nombre_usuario:
        nombre_usuario = correo.split("@")[0]

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        usuario = buscar_usuario_por_proveedor(cur, "google", id_externo)

        if not usuario:
            usuario = buscar_usuario_por_correo(cur, correo)

        if usuario:
            if not usuario["activo"]:
                return jsonify({"error": "Usuario inactivo"}), 403

            cur.execute("""
                UPDATE usuario
                SET proveedor_login = 'google',
                    id_externo = %s,
                    foto_perfil = COALESCE(%s, foto_perfil),
                    fecha_actualizacion = CURRENT_TIMESTAMP
                WHERE id_usuario = %s
            """, (
                id_externo,
                foto_perfil,
                usuario["id_usuario"],
            ))

            usuario = obtener_usuario_por_id(cur, usuario["id_usuario"])
        else:
            cur.execute("""
                INSERT INTO usuario (
                    nombre_usuario,
                    correo,
                    foto_perfil,
                    proveedor_login,
                    id_externo,
                    password_hash
                )
                VALUES (%s, %s, %s, 'google', %s, %s)
            """, (
                nombre_usuario,
                correo,
                foto_perfil,
                id_externo,
                generar_password_temporal(),
            ))

            usuario = obtener_usuario_por_id(cur, cur.lastrowid)

        token = crear_token_sesion(cur, usuario["id_usuario"])
        conn.commit()

        return jsonify(respuesta_login(token, usuario)), 200

    finally:
        cur.close()
        conn.close()


@app.post("/auth/facebook-login")
def facebook_login():
    data = request.get_json(force=False, silent=True) or {}

    id_externo = (data.get("id_externo") or "").strip()
    correo = (data.get("correo") or "").strip().lower()
    nombre_usuario = (data.get("nombre_usuario") or "").strip()
    foto_perfil = (data.get("foto_perfil") or "").strip() or None

    if not id_externo:
        return jsonify({"error": "id_externo de Facebook requerido"}), 400

    if not validar_correo(correo):
        return jsonify({"error": "Correo de Facebook inválido"}), 400

    if not nombre_usuario:
        nombre_usuario = correo.split("@")[0]

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        usuario = buscar_usuario_por_proveedor(cur, "facebook", id_externo)

        if not usuario:
            usuario = buscar_usuario_por_correo(cur, correo)

        if usuario:
            if not usuario["activo"]:
                return jsonify({"error": "Usuario inactivo"}), 403

            cur.execute("""
                UPDATE usuario
                SET proveedor_login = 'facebook',
                    id_externo = %s,
                    foto_perfil = COALESCE(%s, foto_perfil),
                    fecha_actualizacion = CURRENT_TIMESTAMP
                WHERE id_usuario = %s
            """, (
                id_externo,
                foto_perfil,
                usuario["id_usuario"],
            ))

            usuario = obtener_usuario_por_id(cur, usuario["id_usuario"])
        else:
            cur.execute("""
                INSERT INTO usuario (
                    nombre_usuario,
                    correo,
                    foto_perfil,
                    proveedor_login,
                    id_externo,
                    password_hash
                )
                VALUES (%s, %s, %s, 'facebook', %s, %s)
            """, (
                nombre_usuario,
                correo,
                foto_perfil,
                id_externo,
                generar_password_temporal(),
            ))

            usuario = obtener_usuario_por_id(cur, cur.lastrowid)

        token = crear_token_sesion(cur, usuario["id_usuario"])
        conn.commit()

        return jsonify(respuesta_login(token, usuario)), 200

    finally:
        cur.close()
        conn.close()


@app.post("/auth/phone-login")
def phone_login():
    data = request.get_json(force=False, silent=True) or {}

    telefono = (data.get("telefono") or "").strip()

    if not validar_telefono(telefono):
        return jsonify({"error": "Teléfono inválido"}), 400

    codigo = str(secrets.randbelow(900000) + 100000)
    fecha_expiracion = datetime.now() + timedelta(minutes=PHONE_CODE_MINUTES)
    correo_falso = f"{telefono.replace('+', '')}@phone.local"

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        usuario = buscar_usuario_por_telefono(cur, telefono)

        if usuario:
            cur.execute("""
                UPDATE usuario
                SET codigo_verificacion = %s,
                    fecha_codigo_expiracion = %s,
                    proveedor_login = 'phone',
                    fecha_actualizacion = CURRENT_TIMESTAMP
                WHERE id_usuario = %s
            """, (
                codigo,
                fecha_expiracion,
                usuario["id_usuario"],
            ))
        else:
            cur.execute("""
                INSERT INTO usuario (
                    nombre_usuario,
                    correo,
                    telefono,
                    proveedor_login,
                    codigo_verificacion,
                    fecha_codigo_expiracion,
                    password_hash
                )
                VALUES (%s, %s, %s, 'phone', %s, %s, %s)
            """, (
                f"Usuario {telefono}",
                correo_falso,
                telefono,
                codigo,
                fecha_expiracion,
                generar_password_temporal(),
            ))

        conn.commit()

        return jsonify({
            "mensaje": "Código de verificación generado",
            "telefono": telefono,
            "codigo_demo": codigo,
            "nota": "En producción este código se enviaría por SMS"
        }), 200

    finally:
        cur.close()
        conn.close()


@app.post("/auth/verificar-codigo")
def verificar_codigo():
    data = request.get_json(force=False, silent=True) or {}

    telefono = (data.get("telefono") or "").strip()
    codigo = (data.get("codigo") or "").strip()

    if not validar_telefono(telefono):
        return jsonify({"error": "Teléfono inválido"}), 400

    if not codigo:
        return jsonify({"error": "Código requerido"}), 400

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        usuario = buscar_usuario_por_telefono(cur, telefono)

        if not usuario:
            return jsonify({"error": "Usuario no encontrado"}), 404

        cur.execute("""
            SELECT
                codigo_verificacion,
                fecha_codigo_expiracion
            FROM usuario
            WHERE id_usuario = %s
            LIMIT 1
        """, (
            usuario["id_usuario"],
        ))

        verificacion = cur.fetchone()

        if not verificacion or not verificacion["codigo_verificacion"]:
            return jsonify({"error": "No hay código activo"}), 400

        if verificacion["codigo_verificacion"] != codigo:
            return jsonify({"error": "Código inválido"}), 401

        if verificacion["fecha_codigo_expiracion"] < datetime.now():
            return jsonify({"error": "Código expirado"}), 401

        cur.execute("""
            UPDATE usuario
            SET codigo_verificacion = NULL,
                fecha_codigo_expiracion = NULL,
                fecha_actualizacion = CURRENT_TIMESTAMP
            WHERE id_usuario = %s
        """, (
            usuario["id_usuario"],
        ))

        usuario = obtener_usuario_por_id(cur, usuario["id_usuario"])
        token = crear_token_sesion(cur, usuario["id_usuario"])
        conn.commit()

        return jsonify(respuesta_login(token, usuario)), 200

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
                u.correo,
                u.telefono,
                u.foto_perfil,
                u.proveedor_login
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
                "telefono": sesion["telefono"],
                "foto_perfil": sesion["foto_perfil"],
                "proveedor_login": sesion["proveedor_login"],
            }
        }), 200

    finally:
        cur.close()
        conn.close()


@app.get("/perfil/<int:id_usuario>")
def obtener_perfil_usuario(id_usuario):
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        perfil = asegurar_perfil_usuario(cur, id_usuario)

        if not perfil:
            return jsonify({"error": "Perfil no encontrado"}), 404

        conn.commit()

        return jsonify(serializar_perfil_usuario(perfil)), 200

    finally:
        cur.close()
        conn.close()


@app.get("/perfil/burbuja/<int:id_usuario>")
def obtener_burbuja_usuario(id_usuario):
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        perfil = asegurar_perfil_usuario(cur, id_usuario)

        if not perfil:
            return jsonify({"error": "Perfil no encontrado"}), 404

        conn.commit()

        return jsonify(serializar_burbuja_usuario(perfil)), 200

    finally:
        cur.close()
        conn.close()


@app.get("/perfil/personalizacion/<int:id_usuario>")
def obtener_personalizacion_perfil(id_usuario):
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        perfil = asegurar_perfil_usuario(cur, id_usuario)

        if not perfil:
            return jsonify({"error": "Perfil no encontrado"}), 404

        conn.commit()

        return jsonify(obtener_opciones_personalizacion(perfil)), 200

    finally:
        cur.close()
        conn.close()


@app.post("/perfil/avatar")
def actualizar_avatar_perfil():
    data = request.get_json(force=False, silent=True) or {}

    id_usuario = data.get("id_usuario")
    avatar_key = data.get("avatar_key")

    if not id_usuario:
        return jsonify({"error": "id_usuario requerido"}), 400

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        result, status = actualizar_avatar_usuario(cur, id_usuario, avatar_key)

        if status == 200:
            conn.commit()
        else:
            conn.rollback()

        return jsonify(result), status

    finally:
        cur.close()
        conn.close()


@app.post("/perfil/puntero")
def actualizar_puntero_perfil():
    data = request.get_json(force=False, silent=True) or {}

    id_usuario = data.get("id_usuario")
    pointer_key = data.get("pointer_key")

    if not id_usuario:
        return jsonify({"error": "id_usuario requerido"}), 400

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        result, status = actualizar_puntero_usuario(cur, id_usuario, pointer_key)

        if status == 200:
            conn.commit()
        else:
            conn.rollback()

        return jsonify(result), status

    finally:
        cur.close()
        conn.close()


# ================== RUN ==================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8001, debug=True, threaded=True)
    