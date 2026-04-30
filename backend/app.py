from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from dotenv import load_dotenv
import os
import random

# ================== LOAD ENV VARIABLES ==================
load_dotenv()

# ================== CONFIG ==================
CANTIDAD_PREGUNTAS = 5   # <- corregido de 3 a 5
CANTIDAD_CATEGORIAS = 11

# ================== APP ==================
app = Flask(__name__)
CORS(app)


# ================== GAME SERVICE - OOP ==================
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
            if control and control.get("preguntas_respondidas") is None:
                control["preguntas_respondidas"] = ""
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
        """Reinicio completo: preguntas Y ruletas vuelven a su estado inicial."""
        control = self.get_control_state()
        if not control:
            return {"error": "no existe control_juego"}, 404

        self.update_control_state(
            id_control=control["id_control"],
            preguntas_restantes=CANTIDAD_PREGUNTAS,
            categorias_restantes=CANTIDAD_CATEGORIAS,
            ultimo_evento="none",
            preguntas_respondidas="",
        )

        return {
            "mensaje": "Juego reiniciado correctamente",
            "preguntas_restantes": CANTIDAD_PREGUNTAS,
            "categorias_restantes": CANTIDAD_CATEGORIAS,
            "ultimo_evento": "none",
            "preguntas_respondidas": "",
        }, 200

    def reset_solo_preguntas(self, id_control, categorias_restantes, ultimo_evento):
        """
        Reinicio parcial: solo vuelven las preguntas a 5.
        Las ruletas NO se tocan — siguen con su conteo actual.
        Se guarda en SQL igual que siempre.
        """
        self.update_control_state(
            id_control=id_control,
            preguntas_restantes=CANTIDAD_PREGUNTAS,
            categorias_restantes=categorias_restantes,  # <- no cambia
            ultimo_evento=ultimo_evento,
            preguntas_respondidas="",                   # <- borra historial de preguntas
        )

    def decide_next_event(self):
        control = self.get_control_state()
        if not control:
            return {"error": "no existe control_juego"}, 404

        preguntas_restantes = int(control["preguntas_restantes"])
        categorias_restantes = int(control.get("categorias_restantes", CANTIDAD_CATEGORIAS))
        preguntas_respondidas = control["preguntas_respondidas"] or ""

        eleccion = random.choice([1, 2])

        if eleccion == 1 and preguntas_restantes > 0:
            siguiente = "pregunta"
        elif eleccion == 2 and categorias_restantes > 0:
            siguiente = "ruleta"
        elif preguntas_restantes > 0:
            siguiente = "pregunta"
        elif categorias_restantes > 0:
            siguiente = "ruleta"
        else:
            siguiente = "fin"

        if siguiente == "ruleta":
            categorias_restantes -= 1
            self.update_control_state(
                id_control=control["id_control"],
                preguntas_restantes=preguntas_restantes,
                categorias_restantes=categorias_restantes,
                ultimo_evento="ruleta",
                preguntas_respondidas=preguntas_respondidas,
            )

        return {
            "siguiente": siguiente,
            "preguntas_restantes": preguntas_restantes,
            "categorias_restantes": categorias_restantes,
        }, 200

    def get_random_question_without_repeating(self):
        control = self.get_control_state()
        if not control:
            return {"error": "no existe control_juego"}, 404

        preguntas_restantes = int(control["preguntas_restantes"])
        preguntas_respondidas = control["preguntas_respondidas"] or ""

        # Si el contador llegó a 0, reiniciamos SOLO las preguntas
        # Las ruletas no se tocan
        if preguntas_restantes <= 0:
            self.reset_solo_preguntas(
                id_control=control["id_control"],
                categorias_restantes=int(control.get("categorias_restantes", CANTIDAD_CATEGORIAS)),
                ultimo_evento=control.get("ultimo_evento", "none"),
            )
            control = self.get_control_state()
            preguntas_restantes = int(control["preguntas_restantes"])
            preguntas_respondidas = ""

        respondidas_list = []
        if preguntas_respondidas.strip():
            respondidas_list = [
                int(x)
                for x in preguntas_respondidas.split(",")
                if x.strip().isdigit()
            ]

        conn = self.get_db_connection()
        cur = conn.cursor(dictionary=True, buffered=True)

        try:
            # Busca una pregunta que no haya salido aún
            if respondidas_list:
                placeholders = ",".join(["%s"] * len(respondidas_list))
                cur.execute(f"""
                    SELECT id, texto_pregunta
                    FROM pregunta
                    WHERE id NOT IN ({placeholders})
                    ORDER BY RAND()
                    LIMIT 1
                """, tuple(respondidas_list))
            else:
                cur.execute("""
                    SELECT id, texto_pregunta
                    FROM pregunta
                    ORDER BY RAND()
                    LIMIT 1
                """)

            pregunta = cur.fetchone()

            # Si no hay preguntas disponibles (no debería pasar, pero por si acaso)
            if not pregunta:
                self.reset_solo_preguntas(
                    id_control=control["id_control"],
                    categorias_restantes=int(control.get("categorias_restantes", CANTIDAD_CATEGORIAS)),
                    ultimo_evento=control.get("ultimo_evento", "none"),
                )
                respondidas_list = []
                cur.execute("""
                    SELECT id, texto_pregunta
                    FROM pregunta
                    ORDER BY RAND()
                    LIMIT 1
                """)
                pregunta = cur.fetchone()

                if not pregunta:
                    return {"error": "no hay preguntas registradas"}, 404

            # Marca esta pregunta como respondida y guarda en SQL
            respondidas_list.append(int(pregunta["id"]))
            nueva_lista = ",".join(map(str, respondidas_list))
            nuevas_preguntas_restantes = max(preguntas_restantes - 1, 0)

            self.update_control_state(
                id_control=control["id_control"],
                preguntas_restantes=nuevas_preguntas_restantes,
                categorias_restantes=int(control.get("categorias_restantes", CANTIDAD_CATEGORIAS)),
                ultimo_evento="pregunta",
                preguntas_respondidas=nueva_lista,
            )

            # Trae las respuestas de esa pregunta
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
                "preguntas_restantes": nuevas_preguntas_restantes,
            }, 200

        finally:
            cur.close()
            conn.close()

    def register_spin_result(self, data):
        category = data.get("category")
        subrace = data.get("subrace")
        role = data.get("role")
        pregunta_id = data.get("pregunta_id")
        respuesta_id = data.get("respuesta_id")

        if not category or not subrace or not role or not pregunta_id or not respuesta_id:
            return {"error": "faltan datos"}, 400

        conn = self.get_db_connection()
        cur = conn.cursor(buffered=True)

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
            return {"mensaje": "Guardado OK"}, 200
        finally:
            cur.close()
            conn.close()


game_service = GiroService()


# ================== ROUTES ==================
@app.get("/health")
def health():
    return jsonify({"ok": True})


@app.get("/categorias")
def obtener_categorias():
    conn = game_service.get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)
    try:
        cur.execute("""
            SELECT DISTINCT category
            FROM personajes
            WHERE category IS NOT NULL AND category <> ''
            ORDER BY category ASC
        """)
        rows = cur.fetchall()
        return jsonify({"categorias": [row["category"] for row in rows]})
    finally:
        cur.close()
        conn.close()


@app.get("/subrazas")
def obtener_subrazas():
    categoria = request.args.get("category")
    if not categoria:
        return jsonify({"error": "category es requerido"}), 400

    conn = game_service.get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)
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
        return jsonify({"category": categoria, "subrazas": [row["subrace"] for row in rows]})
    finally:
        cur.close()
        conn.close()


@app.get("/roles")
def obtener_roles():
    categoria = request.args.get("category")
    subraza = request.args.get("subrace")
    if not categoria or not subraza:
        return jsonify({"error": "category y subrace son requeridos"}), 400

    conn = game_service.get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)
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
        return jsonify({"category": categoria, "subrace": subraza, "roles": [row["role"] for row in rows]})
    finally:
        cur.close()
        conn.close()


@app.get("/personajes-filtrados")
def obtener_personajes_filtrados():
    categoria = request.args.get("category")
    subraza = request.args.get("subrace")
    rol = request.args.get("role")
    if not categoria or not subraza or not rol:
        return jsonify({"error": "category, subrace y role son requeridos"}), 400

    conn = game_service.get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)
    try:
        cur.execute("""
            SELECT id, name, race, subrace, category, origin, role,
                   weapon, damage_type, character_name, morality, threat_level
            FROM personajes
            WHERE category = %s AND subrace = %s AND role = %s
            ORDER BY character_name ASC
        """, (categoria, subraza, rol))
        return jsonify({"category": categoria, "subrace": subraza, "role": rol, "personajes": cur.fetchall()})
    finally:
        cur.close()
        conn.close()


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
        return jsonify(cur.fetchall())
    finally:
        cur.close()
        conn.close()


# ================== RUN ==================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True, threaded=True)
    