from flask import Flask, request, jsonify
import mysql.connector
from dotenv import load_dotenv
import os
import random

# ================== CARGA VARIABLES ==================
load_dotenv()

# ================== APP ==================
app = Flask(__name__)

# ================== CONEXIÓN BD ==================
def get_db_connection():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME")
    )

# ================== FUNCIONES CONTROL JUEGO ==================
def obtener_control_juego():
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT id_control, preguntas_restantes, ultimo_evento
            FROM control_juego
            ORDER BY id_control ASC
            LIMIT 1
        """)
        control = cur.fetchone()
    finally:
        cur.close()
        conn.close()

    return control


def actualizar_control_juego(id_control, preguntas_restantes, ultimo_evento):
    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            UPDATE control_juego
            SET preguntas_restantes = %s,
                ultimo_evento = %s,
                fecha_actualizacion = CURRENT_TIMESTAMP
            WHERE id_control = %s
        """, (preguntas_restantes, ultimo_evento, id_control))
        conn.commit()
    finally:
        cur.close()
        conn.close()


def decidir_siguiente_evento(control):
    preguntas_restantes = control["preguntas_restantes"]
    ultimo_evento = control["ultimo_evento"]

    if preguntas_restantes <= 0:
        return "ruleta"

    if ultimo_evento == "ninguno":
        return "ruleta"

    if ultimo_evento == "pregunta":
        return "ruleta"

    return random.choice(["ruleta", "pregunta"])

# ================== HEALTH ==================
@app.get("/health")
def health():
    return jsonify({"ok": True})

# ================== CATEGORÍAS ==================
@app.get("/categorias")
def obtener_categorias():
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT DISTINCT category
            FROM personajes
            WHERE category IS NOT NULL AND category <> ''
            ORDER BY category ASC
        """)
        rows = cur.fetchall()
        categorias = [row["category"] for row in rows]
    finally:
        cur.close()
        conn.close()

    return jsonify({"categorias": categorias})

# ================== SUBRAZAS ==================
@app.get("/subrazas")
def obtener_subrazas():
    categoria = request.args.get("category")

    if not categoria:
        return jsonify({"error": "category es requerido"}), 400

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT DISTINCT subrace
            FROM personajes
            WHERE category = %s
              AND subrace IS NOT NULL
              AND subrace <> ''
            ORDER BY subrace ASC
        """, (categoria,))
        rows = cur.fetchall()
        subrazas = [row["subrace"] for row in rows]
    finally:
        cur.close()
        conn.close()

    return jsonify({
        "category": categoria,
        "subrazas": subrazas
    })

# ================== ROLES ==================
@app.get("/roles")
def obtener_roles():
    categoria = request.args.get("category")
    subraza = request.args.get("subrace")

    if not categoria or not subraza:
        return jsonify({"error": "category y subrace son requeridos"}), 400

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT DISTINCT role
            FROM personajes
            WHERE category = %s
              AND subrace = %s
              AND role IS NOT NULL
              AND role <> ''
            ORDER BY role ASC
        """, (categoria, subraza))
        rows = cur.fetchall()
        roles = [row["role"] for row in rows]
    finally:
        cur.close()
        conn.close()

    return jsonify({
        "category": categoria,
        "subrace": subraza,
        "roles": roles
    })

# ================== PERSONAJES FILTRADOS ==================
@app.get("/personajes-filtrados")
def obtener_personajes_filtrados():
    categoria = request.args.get("category")
    subraza = request.args.get("subrace")
    rol = request.args.get("role")

    if not categoria or not subraza or not rol:
        return jsonify({"error": "category, subrace y role son requeridos"}), 400

    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT
                id,
                name,
                race,
                subrace,
                category,
                origin,
                role,
                weapon,
                damage_type,
                character_name,
                morality,
                threat_level
            FROM personajes
            WHERE category = %s
              AND subrace = %s
              AND role = %s
            ORDER BY character_name ASC
        """, (categoria, subraza, rol))
        rows = cur.fetchall()
    finally:
        cur.close()
        conn.close()

    return jsonify({
        "category": categoria,
        "subrace": subraza,
        "role": rol,
        "personajes": rows
    })

# ================== PREGUNTA RANDOM ==================
@app.get("/pregunta-random")
def obtener_pregunta_random():
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT id, texto_pregunta
            FROM pregunta
            ORDER BY RAND()
            LIMIT 1
        """)
        pregunta = cur.fetchone()

        if not pregunta:
            return jsonify({"error": "no hay preguntas registradas"}), 404

        cur.execute("""
            SELECT id, texto_respuesta
            FROM respuesta
            WHERE pregunta_id = %s
            ORDER BY id ASC
        """, (pregunta["id"],))
        respuestas = cur.fetchall()
    finally:
        cur.close()
        conn.close()

    return jsonify({
        "pregunta_id": pregunta["id"],
        "texto_pregunta": pregunta["texto_pregunta"],
        "respuestas": respuestas
    })

# ================== DECIDIR EVENTO ==================
@app.get("/decidir-evento")
def decidir_evento():
    control = obtener_control_juego()

    if not control:
        return jsonify({"error": "no existe control_juego"}), 404

    siguiente = decidir_siguiente_evento(control)

    preguntas_restantes = control["preguntas_restantes"]

    if siguiente == "pregunta":
        preguntas_restantes -= 1

    actualizar_control_juego(
        id_control=control["id_control"],
        preguntas_restantes=preguntas_restantes,
        ultimo_evento=siguiente
    )

    return jsonify({
        "siguiente": siguiente,
        "preguntas_restantes": preguntas_restantes
    })

# ================== GUARDAR RESULTADO ==================
@app.route("/guardar-resultado-completo", methods=["POST"])
def guardar_resultado_completo():
    data = request.get_json(force=False, silent=True) or {}

    category = data.get("category")
    subrace = data.get("subrace")
    role = data.get("role")
    pregunta_id = data.get("pregunta_id")
    respuesta_id = data.get("respuesta_id")

    if not category or not subrace or not role or not pregunta_id or not respuesta_id:
        return jsonify({"error": "faltan datos"}), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            INSERT INTO PRUEBA_RULETA (
                category,
                subrace,
                role,
                pregunta_id,
                respuesta_id
            )
            VALUES (%s, %s, %s, %s, %s)
        """, (category, subrace, role, pregunta_id, respuesta_id))
        conn.commit()
    finally:
        cur.close()
        conn.close()

    return jsonify({"mensaje": "Guardado OK"})

# ================== HISTORIAL ==================
@app.get("/historial")
def ver_historial():
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute("""
            SELECT 
                pr.id,
                pr.fecha_completa,
                pr.category,
                pr.subrace,
                pr.role,
                p.texto_pregunta,
                r.texto_respuesta
            FROM PRUEBA_RULETA pr
            LEFT JOIN pregunta p ON pr.pregunta_id = p.id
            LEFT JOIN respuesta r ON pr.respuesta_id = r.id
            ORDER BY pr.id DESC
            LIMIT 50
        """)
        registros = cur.fetchall()
    finally:
        cur.close()
        conn.close()

    return jsonify(registros)

# ================== RUN ==================
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000, debug=True)