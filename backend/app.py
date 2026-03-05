from flask import Flask, request, jsonify
import mysql.connector
from dotenv import load_dotenv
import os

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
# ================== GUARDAR RESULTADO ==================

@app.route("/guardar-resultado", methods=["POST"])
def guardar_resultado():
    data = request.get_json(force=False, silent=True) or {}

    category = (
        data.get("category")
        or request.form.get("category")
        or request.args.get("category")
    )

    subrace = (
        data.get("subrace")
        or request.form.get("subrace")
        or request.args.get("subrace")
    )

    role = (
        data.get("role")
        or request.form.get("role")
        or request.args.get("role")
    )

    if not category or not subrace or not role:
        return jsonify({
            "error": "category, subrace y role son requeridos",
            "data_recibida": data,
            "form_recibido": request.form.to_dict(),
            "args_recibidos": request.args.to_dict()
        }), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            INSERT INTO PRUEBA_RULETA (category, subrace, role)
            VALUES (%s, %s, %s)
        """, (category, subrace, role))
        conn.commit()
    finally:
        cur.close()
        conn.close()

    return jsonify({
        "mensaje": "Guardado",
        "category": category,
        "subrace": subrace,
        "role": role
    })

# ================== RUN ==================
if __name__== "__main__":
    app.run(host="127.0.0.1", port=8000, debug=True)
