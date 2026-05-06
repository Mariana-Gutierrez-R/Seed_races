from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from dotenv import load_dotenv
import os
import random

# ================== LOAD ENV VARIABLES ==================
load_dotenv()

# ================== CONFIG ==================
CANTIDAD_PREGUNTAS = 5
CANTIDAD_RULETAS = 9

# ================== APP ==================
app = Flask(__name__)
CORS(app)

# ================== GAME SERVICE ==================
class GiroService:
    def __init__(self):
        self.db_host = os.getenv("DB_HOST")
        self.db_user = os.getenv("DB_USER")
        self.db_password = os.getenv("DB_PASSWORD")
        self.db_name = os.getenv("DB_NAME")

    def get_db_connection(self):
        return mysql.connector.connect(
            host=self.db_host,
            user=self.db_user,
            password=self.db_password,
            database=self.db_name,
            autocommit=False,
            connection_timeout=5,
        )

    def get_control_state(self):
        conn = self.get_db_connection()
        cur = conn.cursor(dictionary=True, buffered=True)

        try:
            cur.execute("""
                SELECT
                    id_control,
                    preguntas_restantes,
                    categorias_restantes,
                    ultimo_evento,
                    preguntas_respondidas
                FROM control_juego
                ORDER BY id_control ASC
                LIMIT 1
            """)
            control = cur.fetchone()

            if control:
                control["preguntas_restantes"] = int(control["preguntas_restantes"] or 0)
                control["categorias_restantes"] = int(control["categorias_restantes"] or 0)
                control["ultimo_evento"] = control["ultimo_evento"] or "none"
                control["preguntas_respondidas"] = control["preguntas_respondidas"] or ""

            return control
        finally:
            cur.close()
            conn.close()

    def update_control_state(
        self,
        id_control,
        preguntas_restantes,
        categorias_restantes,
        ultimo_evento,
        preguntas_respondidas,
    ):
        conn = self.get_db_connection()
        cur = conn.cursor(buffered=True)

        try:
            cur.execute("""
                UPDATE control_juego
                SET preguntas_restantes = %s,
                    categorias_restantes = %s,
                    ultimo_evento = %s,
                    preguntas_respondidas = %s,
                    fecha_actualizacion = CURRENT_TIMESTAMP
                WHERE id_control = %s
            """, (
                preguntas_restantes,
                categorias_restantes,
                ultimo_evento,
                preguntas_respondidas,
                id_control,
            ))
            conn.commit()
        finally:
            cur.close()
            conn.close()

    def reset_game(self):
        control = self.get_control_state()

        if not control:
            return {"error": "no existe control_juego"}, 404

        self.update_control_state(
            id_control=control["id_control"],
            preguntas_restantes=CANTIDAD_PREGUNTAS,
            categorias_restantes=CANTIDAD_RULETAS,
            ultimo_evento="none",
            preguntas_respondidas="",
        )

        return {
            "mensaje": "Juego reiniciado correctamente",
            "preguntas_restantes": CANTIDAD_PREGUNTAS,
            "categorias_restantes": CANTIDAD_RULETAS,
            "ultimo_evento": "none",
            "preguntas_respondidas": "",
        }, 200

    def decide_next_event(self):
        evento_actual = request.args.get("evento_actual", "ruleta")
        ruleta_completa = request.args.get("ruleta_completa", "false").lower() == "true"

        control = self.get_control_state()

        if not control:
            return {"error": "no existe control_juego"}, 404

        preguntas_restantes = control["preguntas_restantes"]
        ruletas_restantes = control["categorias_restantes"]
        preguntas_respondidas = control["preguntas_respondidas"]

        if evento_actual == "ruleta" and ruleta_completa and ruletas_restantes > 0:
            ruletas_restantes -= 1

        if preguntas_restantes <= 0:
            preguntas_restantes = CANTIDAD_PREGUNTAS
            preguntas_respondidas = ""

        if ruletas_restantes <= 0:
            ruletas_restantes = CANTIDAD_RULETAS

        if evento_actual == "pregunta":
            siguiente = "ruleta"
        else:
            siguiente = random.choice(["ruleta", "pregunta"])

        self.update_control_state(
            id_control=control["id_control"],
            preguntas_restantes=preguntas_restantes,
            categorias_restantes=ruletas_restantes,
            ultimo_evento=siguiente,
            preguntas_respondidas=preguntas_respondidas,
        )

        return {
            "siguiente": siguiente,
            "preguntas_restantes": preguntas_restantes,
            "categorias_restantes": ruletas_restantes,
            "ultimo_evento": siguiente,
            "variable_aleatoria_controlada": "random.choice(['ruleta', 'pregunta'])",
        }, 200

    def get_random_question_without_repeating(self):
        control = self.get_control_state()

        if not control:
            return {"error": "no existe control_juego"}, 404

        preguntas_restantes = control["preguntas_restantes"]
        ruletas_restantes = control["categorias_restantes"]
        preguntas_respondidas = control["preguntas_respondidas"]

        if preguntas_restantes <= 0:
            preguntas_restantes = CANTIDAD_PREGUNTAS
            preguntas_respondidas = ""

        respondidas = []
        if preguntas_respondidas.strip():
            respondidas = [
                int(x)
                for x in preguntas_respondidas.split(",")
                if x.strip().isdigit()
            ]

        conn = self.get_db_connection()
        cur = conn.cursor(dictionary=True, buffered=True)

        try:
            if respondidas:
                placeholders = ",".join(["%s"] * len(respondidas))
                cur.execute(f"""
                    SELECT id, texto_pregunta
                    FROM pregunta
                    WHERE id NOT IN ({placeholders})
                    ORDER BY RAND()
                    LIMIT 1
                """, tuple(respondidas))
            else:
                cur.execute("""
                    SELECT id, texto_pregunta
                    FROM pregunta
                    ORDER BY RAND()
                    LIMIT 1
                """)

            pregunta = cur.fetchone()

            if not pregunta:
                respondidas = []
                preguntas_restantes = CANTIDAD_PREGUNTAS

                cur.execute("""
                    SELECT id, texto_pregunta
                    FROM pregunta
                    ORDER BY RAND()
                    LIMIT 1
                """)
                pregunta = cur.fetchone()

                if not pregunta:
                    return {"error": "no hay preguntas registradas"}, 404

            respondidas.append(int(pregunta["id"]))
            nuevas_preguntas_restantes = preguntas_restantes - 1

            if nuevas_preguntas_restantes <= 0:
                preguntas_restantes_guardar = CANTIDAD_PREGUNTAS
                preguntas_respondidas_guardar = ""
            else:
                preguntas_restantes_guardar = nuevas_preguntas_restantes
                preguntas_respondidas_guardar = ",".join(map(str, respondidas))

            self.update_control_state(
                id_control=control["id_control"],
                preguntas_restantes=preguntas_restantes_guardar,
                categorias_restantes=ruletas_restantes,
                ultimo_evento="pregunta",
                preguntas_respondidas=preguntas_respondidas_guardar,
            )

            cur.execute("""
                SELECT id, texto_respuesta
                FROM respuesta
                WHERE pregunta_id = %s
                ORDER BY id ASC
            """, (pregunta["id"],))

            respuestas = cur.fetchall()

            return {
                "pregunta_id": pregunta["id"],
                "texto_pregunta": pregunta["texto_pregunta"],
                "respuestas": respuestas,
                "preguntas_restantes": preguntas_restantes_guardar,
                "categorias_restantes": ruletas_restantes,
            }, 200
        finally:
            cur.close()
            conn.close()

    def get_id_by_name(self, table_name, id_column, name_column, value):
        conn = self.get_db_connection()
        cur = conn.cursor(dictionary=True, buffered=True)

        try:
            cur.execute(f"""
                SELECT {id_column} AS id
                FROM {table_name}
                WHERE {name_column} = %s
                LIMIT 1
            """, (value,))
            row = cur.fetchone()
            return row["id"] if row else None
        finally:
            cur.close()
            conn.close()

    def resolve_ids(self, data):
        return {
            "id_origin": self.get_id_by_name("origin", "id_origin", "origin_name", data.get("origin")),
            "id_category": self.get_id_by_name("category", "id_category", "category_name", data.get("category")),
            "id_race": self.get_id_by_name("race", "id_race", "race_name", data.get("race")),
            "id_subrace": self.get_id_by_name("subrace", "id_subrace", "subrace_name", data.get("subrace")),
            "id_role": self.get_id_by_name("role", "id_role", "role_name", data.get("role")),
            "id_weapon": self.get_id_by_name("weapon", "id_weapon", "weapon_name", data.get("weapon")),
            "id_damage_type": self.get_id_by_name("damage_type", "id_damage_type", "damage_type_name", data.get("damage_type")),
            "id_morality": self.get_id_by_name("morality", "id_morality", "morality_name", data.get("morality")),
            "id_threat_level": self.get_id_by_name("threat_level", "id_threat_level", "threat_level_name", data.get("threat_level")),
        }

    def register_spin_result(self, data):
        pregunta_id = data.get("pregunta_id")
        respuesta_id = data.get("respuesta_id")

        if not pregunta_id or not respuesta_id:
            return {"error": "faltan datos de pregunta o respuesta"}, 400

        ids = self.resolve_ids(data)

        if not all(ids.values()):
            return {
                "error": "no se pudieron resolver todos los IDs",
                "ids": ids,
            }, 400

        conn = self.get_db_connection()
        cur = conn.cursor(buffered=True)

        try:
            cur.execute("""
                INSERT INTO prueba_ruleta (
                    id_origin,
                    id_category,
                    id_race,
                    id_subrace,
                    id_role,
                    id_weapon,
                    id_damage_type,
                    id_morality,
                    id_threat_level,
                    pregunta_id,
                    respuesta_id
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                ids["id_origin"],
                ids["id_category"],
                ids["id_race"],
                ids["id_subrace"],
                ids["id_role"],
                ids["id_weapon"],
                ids["id_damage_type"],
                ids["id_morality"],
                ids["id_threat_level"],
                pregunta_id,
                respuesta_id,
            ))
            conn.commit()

            return {"mensaje": "Guardado OK", "ids": ids}, 200
        finally:
            cur.close()
            conn.close()


game_service = GiroService()

# ================== QUERY HELPERS ==================
def build_filter(params, flexible=False):
    joins = """
        INNER JOIN origin o ON c.id_origin = o.id_origin
        INNER JOIN category cat ON c.id_category = cat.id_category
        INNER JOIN race r ON c.id_race = r.id_race
        INNER JOIN subrace s ON c.id_subrace = s.id_subrace
        INNER JOIN role ro ON c.id_role = ro.id_role
        INNER JOIN weapon w ON c.id_weapon = w.id_weapon
        INNER JOIN damage_type dt ON c.id_damage_type = dt.id_damage_type
        INNER JOIN morality m ON c.id_morality = m.id_morality
        INNER JOIN threat_level tl ON c.id_threat_level = tl.id_threat_level
    """

    wheres = []
    values = []

    if params.get("origin"):
        wheres.append("o.origin_name = %s")
        values.append(params["origin"])

    if params.get("category"):
        wheres.append("cat.category_name = %s")
        values.append(params["category"])

    if params.get("race"):
        wheres.append("r.race_name = %s")
        values.append(params["race"])

    if params.get("subrace"):
        wheres.append("s.subrace_name = %s")
        values.append(params["subrace"])

    if not flexible:
        if params.get("role"):
            wheres.append("ro.role_name = %s")
            values.append(params["role"])

        if params.get("weapon"):
            wheres.append("w.weapon_name = %s")
            values.append(params["weapon"])

        if params.get("damage_type"):
            wheres.append("dt.damage_type_name = %s")
            values.append(params["damage_type"])

        if params.get("morality"):
            wheres.append("m.morality_name = %s")
            values.append(params["morality"])

        if params.get("threat_level"):
            wheres.append("tl.threat_level_name = %s")
            values.append(params["threat_level"])

    where_clause = "WHERE " + " AND ".join(wheres) if wheres else ""
    return joins, where_clause, values


def query_distinct(select_expr, params, flexible=False):
    joins, where_clause, values = build_filter(params, flexible=flexible)

    conn = game_service.get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        cur.execute(f"""
            SELECT DISTINCT {select_expr} AS valor
            FROM characters c
            {joins}
            {where_clause}
            ORDER BY valor ASC
        """, tuple(values))

        return [row["valor"] for row in cur.fetchall() if row["valor"]]
    finally:
        cur.close()
        conn.close()

# ================== ROUTES ==================
@app.get("/health")
def health():
    return jsonify({"ok": True})


@app.get("/origenes")
def obtener_origenes():
    return jsonify({"origenes": query_distinct("o.origin_name", {})})


@app.get("/categorias")
def obtener_categorias():
    params = {"origin": request.args.get("origin")}
    return jsonify({"categorias": query_distinct("cat.category_name", params)})


@app.get("/razas")
def obtener_razas():
    params = {
        "origin": request.args.get("origin"),
        "category": request.args.get("category"),
    }
    return jsonify({"razas": query_distinct("r.race_name", params)})


@app.get("/subrazas")
def obtener_subrazas():
    params = {
        "origin": request.args.get("origin"),
        "category": request.args.get("category"),
        "race": request.args.get("race"),
    }
    return jsonify({"subrazas": query_distinct("s.subrace_name", params)})


@app.get("/roles")
def obtener_roles():
    params = {
        "origin": request.args.get("origin"),
        "category": request.args.get("category"),
        "race": request.args.get("race"),
        "subrace": request.args.get("subrace"),
    }
    return jsonify({"roles": query_distinct("ro.role_name", params, flexible=True)})


@app.get("/armas")
def obtener_armas():
    params = {
        "origin": request.args.get("origin"),
        "category": request.args.get("category"),
        "race": request.args.get("race"),
        "subrace": request.args.get("subrace"),
    }
    return jsonify({"armas": query_distinct("w.weapon_name", params, flexible=True)})


@app.get("/tipos-dano")
def obtener_tipos_dano():
    params = {
        "origin": request.args.get("origin"),
        "category": request.args.get("category"),
        "race": request.args.get("race"),
        "subrace": request.args.get("subrace"),
    }
    return jsonify({"tipos_dano": query_distinct("dt.damage_type_name", params, flexible=True)})


@app.get("/moralidades")
def obtener_moralidades():
    params = {
        "origin": request.args.get("origin"),
        "category": request.args.get("category"),
        "race": request.args.get("race"),
        "subrace": request.args.get("subrace"),
    }
    return jsonify({"moralidades": query_distinct("m.morality_name", params, flexible=True)})


@app.get("/niveles-amenaza")
def obtener_niveles_amenaza():
    params = {
        "origin": request.args.get("origin"),
        "category": request.args.get("category"),
        "race": request.args.get("race"),
        "subrace": request.args.get("subrace"),
    }
    return jsonify({"niveles_amenaza": query_distinct("tl.threat_level_name", params, flexible=True)})


@app.get("/decidir-evento")
def decidir_evento():
    result, status = game_service.decide_next_event()
    return jsonify(result), status


@app.get("/pregunta-random")
def obtener_pregunta_random():
    result, status = game_service.get_random_question_without_repeating()
    return jsonify(result), status


@app.route("/guardar-resultado-completo", methods=["POST"])
def guardar_resultado_completo():
    data = request.get_json(force=False, silent=True) or {}
    result, status = game_service.register_spin_result(data)
    return jsonify(result), status


@app.post("/reiniciar-juego")
def reiniciar_juego():
    result, status = game_service.reset_game()
    return jsonify(result), status


@app.get("/historial")
def ver_historial():
    conn = game_service.get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        cur.execute("""
            SELECT
                pr.id,
                pr.Fecha_completa,
                pr.id_origin,
                pr.id_category,
                pr.id_race,
                pr.id_subrace,
                pr.id_role,
                pr.id_weapon,
                pr.id_damage_type,
                pr.id_morality,
                pr.id_threat_level,
                pr.pregunta_id,
                pr.respuesta_id,
                p.texto_pregunta,
                r.texto_respuesta
            FROM prueba_ruleta pr
            LEFT JOIN pregunta p ON pr.pregunta_id = p.id
            LEFT JOIN respuesta r ON pr.respuesta_id = r.id
            ORDER BY pr.id DESC
            LIMIT 50
        """)

        return jsonify(cur.fetchall())
    finally:
        cur.close()
        conn.close()

# ================== RUN ==================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True, threaded=True)
    