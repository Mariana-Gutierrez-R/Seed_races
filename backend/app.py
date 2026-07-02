from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from database.mysql import get_db_connection as create_db_connection
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
    def get_db_connection(self):
        return create_db_connection()

    def create_session(self, id_usuario=None):
        conn = self.get_db_connection()
        cur = conn.cursor(buffered=True)

        try:
            cur.execute("""
                INSERT INTO sesion_juego (
                    id_usuario
                )
                VALUES (%s)
            """, (
                id_usuario,
            ))
            conn.commit()
            return cur.lastrowid
        finally:
            cur.close()
            conn.close()

    def get_usuario_from_sesion(self, id_sesion):
        if not id_sesion:
            return None

        conn = self.get_db_connection()
        cur = conn.cursor(dictionary=True, buffered=True)

        try:
            cur.execute("""
                SELECT id_usuario
                FROM sesion_juego
                WHERE id_sesion = %s
                LIMIT 1
            """, (
                id_sesion,
            ))
            sesion = cur.fetchone()
            return sesion["id_usuario"] if sesion else None
        finally:
            cur.close()
            conn.close()

    def get_control_state(self):
        conn = self.get_db_connection()
        cur = conn.cursor(dictionary=True, buffered=True)

        try:
            cur.execute("""
                SELECT
                    id_control,
                    id_sesion,
                    preguntas_restantes,
                    categorias_restantes,
                    preguntas_respondidas,
                    ruletas_respondidas,
                    ultimo_evento
                FROM control_juego
                ORDER BY id_control ASC
                LIMIT 1
            """)
            control = cur.fetchone()

            if control:
                control["id_sesion"] = int(control["id_sesion"] or 0)
                control["preguntas_restantes"] = int(control["preguntas_restantes"] or 0)
                control["categorias_restantes"] = int(control["categorias_restantes"] or 0)
                control["preguntas_respondidas"] = control["preguntas_respondidas"] or ""
                control["ruletas_respondidas"] = control["ruletas_respondidas"] or ""
                control["ultimo_evento"] = control["ultimo_evento"] or "none"

            return control
        finally:
            cur.close()
            conn.close()

    def update_control_state(
        self,
        id_control,
        id_sesion,
        preguntas_restantes,
        categorias_restantes,
        preguntas_respondidas,
        ruletas_respondidas,
        ultimo_evento,
    ):
        conn = self.get_db_connection()
        cur = conn.cursor(buffered=True)

        try:
            cur.execute("""
                UPDATE control_juego
                SET id_sesion = %s,
                    preguntas_restantes = %s,
                    categorias_restantes = %s,
                    preguntas_respondidas = %s,
                    ruletas_respondidas = %s,
                    ultimo_evento = %s,
                    fecha_actualizacion = CURRENT_TIMESTAMP
                WHERE id_control = %s
            """, (
                id_sesion,
                preguntas_restantes,
                categorias_restantes,
                preguntas_respondidas,
                ruletas_respondidas,
                ultimo_evento,
                id_control,
            ))
            conn.commit()
        finally:
            cur.close()
            conn.close()

    def reset_game(self, data=None):
        data = data or {}
        id_usuario = data.get("id_usuario")

        control = self.get_control_state()

        if not control:
            return {"error": "no existe control_juego"}, 404

        nueva_sesion = self.create_session(id_usuario)

        self.update_control_state(
            id_control=control["id_control"],
            id_sesion=nueva_sesion,
            preguntas_restantes=CANTIDAD_PREGUNTAS,
            categorias_restantes=CANTIDAD_RULETAS,
            preguntas_respondidas="",
            ruletas_respondidas="",
            ultimo_evento="none",
        )

        return {
            "mensaje": "Juego reiniciado correctamente",
            "id_sesion": nueva_sesion,
            "id_usuario": id_usuario,
            "preguntas_restantes": CANTIDAD_PREGUNTAS,
            "categorias_restantes": CANTIDAD_RULETAS,
            "preguntas_respondidas": "",
            "ruletas_respondidas": "",
            "ultimo_evento": "none",
        }, 200

    def decide_next_event(self):
        evento_actual = request.args.get("evento_actual", "none")

        control = self.get_control_state()

        if not control:
            return {"error": "no existe control_juego"}, 404

        preguntas_restantes = control["preguntas_restantes"]
        ruletas_restantes = control["categorias_restantes"]
        preguntas_respondidas = control["preguntas_respondidas"]
        ruletas_respondidas = control["ruletas_respondidas"]

        if evento_actual == "ruleta" and ruletas_restantes > 0:
            ruleta_numero = CANTIDAD_RULETAS - ruletas_restantes + 1

            respondidas = [
                x for x in ruletas_respondidas.split(",")
                if x.strip().isdigit()
            ]

            if str(ruleta_numero) not in respondidas:
                respondidas.append(str(ruleta_numero))

            ruletas_respondidas = ",".join(respondidas)
            ruletas_restantes = max(ruletas_restantes - 1, 0)

        hay_preguntas = preguntas_restantes > 0
        hay_ruletas = ruletas_restantes > 0

        if not hay_preguntas and not hay_ruletas:
            preguntas_restantes = CANTIDAD_PREGUNTAS
            ruletas_restantes = CANTIDAD_RULETAS
            preguntas_respondidas = ""
            ruletas_respondidas = ""
            siguiente = "ruleta"
        elif not hay_preguntas and hay_ruletas:
            siguiente = "ruleta"
        elif hay_preguntas and not hay_ruletas:
            siguiente = "pregunta"
        elif evento_actual == "pregunta":
            siguiente = "ruleta"
        else:
            siguiente = random.choice(["ruleta", "pregunta"])

        self.update_control_state(
            id_control=control["id_control"],
            id_sesion=control["id_sesion"],
            preguntas_restantes=preguntas_restantes,
            categorias_restantes=ruletas_restantes,
            preguntas_respondidas=preguntas_respondidas,
            ruletas_respondidas=ruletas_respondidas,
            ultimo_evento=siguiente,
        )

        return {
            "siguiente": siguiente,
            "id_sesion": control["id_sesion"],
            "preguntas_restantes": preguntas_restantes,
            "categorias_restantes": ruletas_restantes,
            "preguntas_respondidas": preguntas_respondidas,
            "ruletas_respondidas": ruletas_respondidas,
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
        ruletas_respondidas = control["ruletas_respondidas"]

        if preguntas_restantes <= 0:
            return {"error": "no quedan preguntas disponibles"}, 409

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
                    SELECT id_pregunta, texto_pregunta
                    FROM pregunta
                    WHERE id_pregunta NOT IN ({placeholders})
                    ORDER BY RAND()
                    LIMIT 1
                """, tuple(respondidas))
            else:
                cur.execute("""
                    SELECT id_pregunta, texto_pregunta
                    FROM pregunta
                    ORDER BY RAND()
                    LIMIT 1
                """)

            pregunta = cur.fetchone()

            if not pregunta:
                return {"error": "no hay más preguntas sin repetir"}, 404

            respondidas.append(int(pregunta["id_pregunta"]))
            nuevas_preguntas_restantes = max(preguntas_restantes - 1, 0)

            if nuevas_preguntas_restantes <= 0:
                preguntas_respondidas_guardar = preguntas_respondidas
            else:
                preguntas_respondidas_guardar = ",".join(map(str, respondidas))

            self.update_control_state(
                id_control=control["id_control"],
                id_sesion=control["id_sesion"],
                preguntas_restantes=nuevas_preguntas_restantes,
                categorias_restantes=ruletas_restantes,
                preguntas_respondidas=preguntas_respondidas_guardar,
                ruletas_respondidas=ruletas_respondidas,
                ultimo_evento="pregunta",
            )

            cur.execute("""
                SELECT id_respuesta, texto_respuesta
                FROM respuesta
                WHERE id_pregunta = %s
                ORDER BY id_respuesta ASC
            """, (pregunta["id_pregunta"],))

            respuestas = cur.fetchall()

            return {
                "id_sesion": control["id_sesion"],
                "pregunta_id": pregunta["id_pregunta"],
                "texto_pregunta": pregunta["texto_pregunta"],
                "respuestas": [
                    {
                        "id": r["id_respuesta"],
                        "texto_respuesta": r["texto_respuesta"],
                    }
                    for r in respuestas
                ],
                "preguntas_restantes": nuevas_preguntas_restantes,
                "categorias_restantes": ruletas_restantes,
            }, 200
        finally:
            cur.close()
            conn.close()

    def get_id_by_name(self, table_name, id_column, name_column, value):
        if not value:
            return None

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

    def get_generated_character(self, ids):
        conn = self.get_db_connection()
        cur = conn.cursor(dictionary=True, buffered=True)

        try:
            cur.execute("""
                SELECT
                    c.id_character,
                    c.character_name,
                    o.origin_name,
                    cat.category_name,
                    r.race_name,
                    s.subrace_name,
                    ro.role_name,
                    w.weapon_name,
                    dt.damage_type_name,
                    m.morality_name,
                    tl.threat_level_name
                FROM characters c
                INNER JOIN origin o ON c.id_origin = o.id_origin
                INNER JOIN category cat ON c.id_category = cat.id_category
                INNER JOIN race r ON c.id_race = r.id_race
                INNER JOIN subrace s ON c.id_subrace = s.id_subrace
                INNER JOIN role ro ON c.id_role = ro.id_role
                INNER JOIN weapon w ON c.id_weapon = w.id_weapon
                INNER JOIN damage_type dt ON c.id_damage_type = dt.id_damage_type
                INNER JOIN morality m ON c.id_morality = m.id_morality
                INNER JOIN threat_level tl ON c.id_threat_level = tl.id_threat_level
                WHERE c.id_origin = %s
                  AND c.id_category = %s
                  AND c.id_race = %s
                  AND c.id_subrace = %s
                  AND c.id_role = %s
                  AND c.id_weapon = %s
                  AND c.id_damage_type = %s
                  AND c.id_morality = %s
                  AND c.id_threat_level = %s
                ORDER BY c.character_name ASC
                LIMIT 1
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
            ))

            return cur.fetchone()
        finally:
            cur.close()
            conn.close()

    def add_profile_rewards(self, cur, id_usuario, exp=0, coins=0):
        """
        Suma EXP y Peep Coins al perfil del usuario.

        Esta función centraliza las recompensas del juego para que luego
        se pueda reutilizar en logros, misiones, recompensas diarias o eventos.
        No rompe el flujo si el usuario viene vacío o si no existe perfil.
        """
        if id_usuario is None:
            return {
                "aplicada": False,
                "motivo": "sin id_usuario",
                "exp_sumada": 0,
                "coins_sumadas": 0,
            }

        try:
            id_usuario = int(id_usuario)
        except (TypeError, ValueError):
            return {
                "aplicada": False,
                "motivo": "id_usuario inválido",
                "exp_sumada": 0,
                "coins_sumadas": 0,
            }

        exp = max(int(exp or 0), 0)
        coins = max(int(coins or 0), 0)

        if exp == 0 and coins == 0:
            return {
                "aplicada": False,
                "motivo": "sin recompensa configurada",
                "id_usuario": id_usuario,
                "exp_sumada": 0,
                "coins_sumadas": 0,
            }

        # Asegura que exista perfil_usuario para usuarios antiguos.
        cur.execute("""
            SELECT id_usuario
            FROM perfil_usuario
            WHERE id_usuario = %s
            LIMIT 1
        """, (id_usuario,))
        perfil_existente = cur.fetchone()

        if not perfil_existente:
            cur.execute("""
                SELECT nombre_usuario
                FROM usuario
                WHERE id_usuario = %s
                LIMIT 1
            """, (id_usuario,))
            usuario = cur.fetchone()

            if not usuario:
                return {
                    "aplicada": False,
                    "motivo": "usuario no encontrado",
                    "id_usuario": id_usuario,
                    "exp_sumada": 0,
                    "coins_sumadas": 0,
                }

            apodo = usuario[0] or "Peep Player"

            cur.execute("""
                INSERT INTO perfil_usuario (
                    id_usuario,
                    apodo,
                    avatar_key,
                    pointer_key,
                    exp_total,
                    peep_coins
                )
                VALUES (%s, %s, %s, %s, 0, 0)
            """, (
                id_usuario,
                apodo,
                "maga",
                "puntero_clasico",
            ))

        cur.execute("""
            UPDATE perfil_usuario
            SET exp_total = COALESCE(exp_total, 0) + %s,
                peep_coins = COALESCE(peep_coins, 0) + %s,
                fecha_actualizacion = CURRENT_TIMESTAMP
            WHERE id_usuario = %s
        """, (
            exp,
            coins,
            id_usuario,
        ))

        cur.execute("""
            SELECT exp_total, peep_coins
            FROM perfil_usuario
            WHERE id_usuario = %s
            LIMIT 1
        """, (id_usuario,))
        perfil = cur.fetchone()

        exp_total = int(perfil[0] or 0) if perfil else exp
        peep_coins = int(perfil[1] or 0) if perfil else coins
        nivel_actual = (exp_total // 100) + 1
        exp_siguiente_nivel = nivel_actual * 100
        exp_inicio_nivel = (nivel_actual - 1) * 100
        exp_en_nivel = exp_total - exp_inicio_nivel

        return {
            "aplicada": True,
            "id_usuario": id_usuario,
            "exp_sumada": exp,
            "coins_sumadas": coins,
            "exp_total": exp_total,
            "peep_coins": peep_coins,
            "nivel_actual": nivel_actual,
            "exp_en_nivel": exp_en_nivel,
            "exp_siguiente_nivel": exp_siguiente_nivel,
        }

    def register_roulette_result(self, data):
        control = self.get_control_state()

        if not control:
            return {"error": "no existe control_juego"}, 404

        id_usuario = data.get("id_usuario")
        if id_usuario is None:
            id_usuario = self.get_usuario_from_sesion(control["id_sesion"])

        nombre_tabla_ruleta = data.get("nombre_tabla_ruleta")
        id_ruleta = data.get("id_ruleta")

        # Soporte flexible para que el frontend pueda enviar:
        # 1) id_ruleta + nombre_tabla_ruleta directamente
        # 2) table + value
        # 3) nombre_tabla_ruleta + valor
        if not nombre_tabla_ruleta:
            nombre_tabla_ruleta = data.get("table") or data.get("tabla")

        valor = data.get("valor") or data.get("value")

        tablas_permitidas = {
            "origin": ("origin", "id_origin", "origin_name"),
            "category": ("category", "id_category", "category_name"),
            "race": ("race", "id_race", "race_name"),
            "subrace": ("subrace", "id_subrace", "subrace_name"),
            "role": ("role", "id_role", "role_name"),
            "weapon": ("weapon", "id_weapon", "weapon_name"),
            "damage_type": ("damage_type", "id_damage_type", "damage_type_name"),
            "morality": ("morality", "id_morality", "morality_name"),
            "threat_level": ("threat_level", "id_threat_level", "threat_level_name"),
        }

        if not nombre_tabla_ruleta:
            return {"error": "falta nombre_tabla_ruleta"}, 400

        nombre_tabla_ruleta = str(nombre_tabla_ruleta).strip()

        if nombre_tabla_ruleta not in tablas_permitidas:
            return {
                "error": "nombre_tabla_ruleta no permitido",
                "nombre_tabla_ruleta": nombre_tabla_ruleta,
            }, 400

        tabla, id_col, name_col = tablas_permitidas[nombre_tabla_ruleta]

        if id_ruleta is None:
            if not valor:
                return {
                    "error": "falta id_ruleta o valor para resolver la ruleta",
                    "nombre_tabla_ruleta": nombre_tabla_ruleta,
                }, 400

            id_ruleta = self.get_id_by_name(
                table_name=tabla,
                id_column=id_col,
                name_column=name_col,
                value=valor,
            )

        if id_ruleta is None:
            return {
                "error": "no se pudo resolver id_ruleta",
                "nombre_tabla_ruleta": nombre_tabla_ruleta,
                "valor": valor,
            }, 400

        conn = self.get_db_connection()
        cur = conn.cursor(buffered=True)

        try:
            cur.execute("""
                INSERT INTO registro_ruletas (
                    id_sesion,
                    id_usuario,
                    id_ruleta,
                    nombre_tabla_ruleta
                )
                VALUES (%s, %s, %s, %s)
            """, (
                control["id_sesion"],
                id_usuario,
                int(id_ruleta),
                nombre_tabla_ruleta,
            ))

            id_registro_ruleta = cur.lastrowid

            recompensa_perfil = self.add_profile_rewards(
                cur=cur,
                id_usuario=id_usuario,
                exp=10,
                coins=5,
            )

            conn.commit()

            return {
                "mensaje": "Ruletazo guardado OK",
                "id_sesion": control["id_sesion"],
                "id_usuario": id_usuario,
                "id_registro_ruleta": id_registro_ruleta,
                "id_ruleta": int(id_ruleta),
                "nombre_tabla_ruleta": nombre_tabla_ruleta,
                "recompensa_perfil": recompensa_perfil,
            }, 200
        finally:
            cur.close()
            conn.close()

    def register_question_result(self, data):
        control = self.get_control_state()

        if not control:
            return {"error": "no existe control_juego"}, 404

        pregunta_id = data.get("pregunta_id")
        respuesta_id = data.get("respuesta_id")
        id_tipo_dibujo = data.get("id_tipo_dibujo")

        # Permite que el frontend envíe el nombre del tipo de dibujo en vez del ID.
        if id_tipo_dibujo is None and data.get("tipo_dibujo"):
            id_tipo_dibujo = self.get_id_by_name(
                table_name="tipo_dibujo",
                id_column="id_tipo_dibujo",
                name_column="nombre_tipo_dibujo",
                value=data.get("tipo_dibujo"),
            )

        # Caso 1: respuesta normal de pregunta.
        # Caso 2: selección final de tipo de dibujo, sin pregunta/respuesta.
        if not id_tipo_dibujo and (not pregunta_id or not respuesta_id):
            return {
                "error": "faltan datos: pregunta/respuesta o id_tipo_dibujo",
            }, 400

        id_usuario = data.get("id_usuario")
        if id_usuario is None:
            id_usuario = self.get_usuario_from_sesion(control["id_sesion"])

        conn = self.get_db_connection()
        cur = conn.cursor(buffered=True)

        try:
            cur.execute("""
                INSERT INTO registro_preguntas (
                    id_sesion,
                    id_usuario,
                    id_pregunta,
                    id_respuesta,
                    id_tipo_dibujo
                )
                VALUES (%s, %s, %s, %s, %s)
            """, (
                control["id_sesion"],
                id_usuario,
                pregunta_id,
                respuesta_id,
                id_tipo_dibujo,
            ))

            id_registro_pregunta = cur.lastrowid

            if pregunta_id and respuesta_id:
                recompensa_perfil = self.add_profile_rewards(
                    cur=cur,
                    id_usuario=id_usuario,
                    exp=15,
                    coins=8,
                )
                tipo_recompensa = "pregunta"
            else:
                recompensa_perfil = self.add_profile_rewards(
                    cur=cur,
                    id_usuario=id_usuario,
                    exp=20,
                    coins=10,
                )
                tipo_recompensa = "tipo_dibujo"

            conn.commit()

            return {
                "mensaje": "Registro de pregunta guardado OK",
                "id_sesion": control["id_sesion"],
                "id_usuario": id_usuario,
                "id_registro_pregunta": id_registro_pregunta,
                "id_tipo_dibujo": id_tipo_dibujo,
                "tipo_recompensa": tipo_recompensa,
                "recompensa_perfil": recompensa_perfil,
            }, 200
        finally:
            cur.close()
            conn.close()

    # ================== REWARD SERVICE ==================
    def get_reward_summary(self, id_sesion=None):
        """
        Calcula el puntaje de la sesión actual y lista las recompensas disponibles.

        Puntaje base:
        - cada ruletazo guardado suma 10 puntos
        - cada pregunta respondida suma 5 puntos
        - escoger tipo de dibujo suma 20 puntos
        """
        control = self.get_control_state()

        if not control:
            return {"error": "no existe control_juego"}, 404

        if id_sesion is None:
            id_sesion = control["id_sesion"]

        conn = self.get_db_connection()
        cur = conn.cursor(dictionary=True, buffered=True)

        try:
            cur.execute("""
                SELECT COUNT(*) AS total_ruletas
                FROM registro_ruletas
                WHERE id_sesion = %s
            """, (id_sesion,))
            total_ruletas = int((cur.fetchone() or {}).get("total_ruletas") or 0)

            cur.execute("""
                SELECT COUNT(*) AS total_preguntas
                FROM registro_preguntas
                WHERE id_sesion = %s
                  AND id_pregunta IS NOT NULL
                  AND id_respuesta IS NOT NULL
            """, (id_sesion,))
            total_preguntas = int((cur.fetchone() or {}).get("total_preguntas") or 0)

            cur.execute("""
                SELECT COUNT(*) AS total_tipo_dibujo
                FROM registro_preguntas
                WHERE id_sesion = %s
                  AND id_tipo_dibujo IS NOT NULL
            """, (id_sesion,))
            total_tipo_dibujo = int((cur.fetchone() or {}).get("total_tipo_dibujo") or 0)

            puntos_ruletas = total_ruletas * 10
            puntos_preguntas = total_preguntas * 5
            puntos_tipo_dibujo = total_tipo_dibujo * 20
            puntos_totales = puntos_ruletas + puntos_preguntas + puntos_tipo_dibujo

            cur.execute("""
                SELECT
                    id_recompensa,
                    nombre_recompensa,
                    descripcion_recompensa,
                    puntos_requeridos,
                    activo
                FROM recompensa
                WHERE activo = 1
                ORDER BY puntos_requeridos ASC, id_recompensa ASC
            """)
            recompensas = cur.fetchall()

            recompensas_disponibles = []
            siguiente_recompensa = None

            for recompensa in recompensas:
                puntos_requeridos = int(recompensa.get("puntos_requeridos") or 0)
                faltan = max(puntos_requeridos - puntos_totales, 0)

                item = {
                    "id_recompensa": recompensa["id_recompensa"],
                    "nombre_recompensa": recompensa["nombre_recompensa"],
                    "descripcion_recompensa": recompensa.get("descripcion_recompensa"),
                    "puntos_requeridos": puntos_requeridos,
                    "desbloqueada": puntos_totales >= puntos_requeridos,
                    "puntos_faltantes": faltan,
                }

                if item["desbloqueada"]:
                    recompensas_disponibles.append(item)
                elif siguiente_recompensa is None:
                    siguiente_recompensa = item

            return {
                "id_sesion": id_sesion,
                "puntos_totales": puntos_totales,
                "detalle_puntaje": {
                    "total_ruletas": total_ruletas,
                    "puntos_ruletas": puntos_ruletas,
                    "total_preguntas": total_preguntas,
                    "puntos_preguntas": puntos_preguntas,
                    "total_tipo_dibujo": total_tipo_dibujo,
                    "puntos_tipo_dibujo": puntos_tipo_dibujo,
                },
                "recompensas_disponibles": recompensas_disponibles,
                "siguiente_recompensa": siguiente_recompensa,
            }, 200
        finally:
            cur.close()
            conn.close()

    def grant_reward(self, data=None):
        """
        Guarda la recompensa obtenida por la sesión actual.
        Si no llega id_recompensa, asigna automáticamente la mejor recompensa desbloqueada.
        """
        data = data or {}
        control = self.get_control_state()

        if not control:
            return {"error": "no existe control_juego"}, 404

        id_sesion = data.get("id_sesion") or control["id_sesion"]
        id_usuario = data.get("id_usuario")
        if id_usuario is None:
            id_usuario = self.get_usuario_from_sesion(id_sesion)

        resumen, status = self.get_reward_summary(id_sesion=id_sesion)
        if status != 200:
            return resumen, status

        disponibles = resumen.get("recompensas_disponibles", [])
        if not disponibles:
            return {
                "error": "todavía no hay recompensas desbloqueadas",
                "id_sesion": id_sesion,
                "puntos_totales": resumen.get("puntos_totales", 0),
                "siguiente_recompensa": resumen.get("siguiente_recompensa"),
            }, 409

        id_recompensa = data.get("id_recompensa")
        if id_recompensa is None:
            recompensa = disponibles[-1]
            id_recompensa = recompensa["id_recompensa"]
        else:
            recompensa = next(
                (r for r in disponibles if int(r["id_recompensa"]) == int(id_recompensa)),
                None,
            )

            if recompensa is None:
                return {
                    "error": "la recompensa no está desbloqueada para esta sesión",
                    "id_recompensa": id_recompensa,
                    "puntos_totales": resumen.get("puntos_totales", 0),
                }, 409

        conn = self.get_db_connection()
        cur = conn.cursor(buffered=True)

        try:
            cur.execute("""
                INSERT INTO registro_recompensas (
                    id_sesion,
                    id_usuario,
                    id_recompensa,
                    puntos_obtenidos
                )
                VALUES (%s, %s, %s, %s)
            """, (
                id_sesion,
                id_usuario,
                int(id_recompensa),
                int(resumen.get("puntos_totales") or 0),
            ))
            conn.commit()

            return {
                "mensaje": "Recompensa guardada OK",
                "id_sesion": id_sesion,
                "id_usuario": id_usuario,
                "id_registro_recompensa": cur.lastrowid,
                "recompensa": recompensa,
                "puntos_totales": resumen.get("puntos_totales", 0),
            }, 200
        finally:
            cur.close()
            conn.close()

    def get_affine_character(self, data):
        """
        Busca el personaje base más afín con base en los campos principales.
        La lógica NO exige coincidencia exacta con arma, daño, moralidad o amenaza,
        porque esos atributos son variaciones creativas del personaje generado.
        """
        base_fields = {
            "origin": ("origin", "id_origin", "origin_name", "c.id_origin", 5),
            "category": ("category", "id_category", "category_name", "c.id_category", 5),
            "race": ("race", "id_race", "race_name", "c.id_race", 5),
            "subrace": ("subrace", "id_subrace", "subrace_name", "c.id_subrace", 5),
            "role": ("role", "id_role", "role_name", "c.id_role", 4),
        }

        resolved = {}
        for key, (table_name, id_column, name_column, sql_column, weight) in base_fields.items():
            value = data.get(key)
            resolved[key] = self.get_id_by_name(
                table_name=table_name,
                id_column=id_column,
                name_column=name_column,
                value=value,
            ) if value else None

        if not any(resolved.values()):
            return {
                "error": "se requiere al menos un dato base para buscar personaje afín",
                "campos_base": ["origin", "category", "race", "subrace", "role"],
            }, 400

        score_parts = []
        params = []

        for key, (_, _, _, sql_column, weight) in base_fields.items():
            value_id = resolved[key]
            if value_id is not None:
                score_parts.append(f"CASE WHEN {sql_column} = %s THEN {weight} ELSE 0 END")
                params.append(value_id)

        score_sql = " + ".join(score_parts) if score_parts else "0"

        conn = self.get_db_connection()
        cur = conn.cursor(dictionary=True, buffered=True)

        try:
            cur.execute(f"""
                SELECT
                    c.id_character,
                    c.character_name,
                    o.origin_name,
                    cat.category_name,
                    r.race_name,
                    s.subrace_name,
                    ro.role_name,
                    w.weapon_name,
                    dt.damage_type_name,
                    m.morality_name,
                    tl.threat_level_name,
                    ({score_sql}) AS puntaje_afinidad
                FROM characters c
                INNER JOIN origin o ON c.id_origin = o.id_origin
                INNER JOIN category cat ON c.id_category = cat.id_category
                INNER JOIN race r ON c.id_race = r.id_race
                INNER JOIN subrace s ON c.id_subrace = s.id_subrace
                INNER JOIN role ro ON c.id_role = ro.id_role
                INNER JOIN weapon w ON c.id_weapon = w.id_weapon
                INNER JOIN damage_type dt ON c.id_damage_type = dt.id_damage_type
                INNER JOIN morality m ON c.id_morality = m.id_morality
                INNER JOIN threat_level tl ON c.id_threat_level = tl.id_threat_level
                ORDER BY puntaje_afinidad DESC, c.character_name ASC
                LIMIT 1
            """, tuple(params))

            personaje = cur.fetchone()

            if not personaje or int(personaje.get("puntaje_afinidad") or 0) <= 0:
                return {"error": "no se encontró personaje afín"}, 404

            coincidencias = []
            if resolved.get("origin") and personaje["origin_name"] == data.get("origin"):
                coincidencias.append("origin")
            if resolved.get("category") and personaje["category_name"] == data.get("category"):
                coincidencias.append("category")
            if resolved.get("race") and personaje["race_name"] == data.get("race"):
                coincidencias.append("race")
            if resolved.get("subrace") and personaje["subrace_name"] == data.get("subrace"):
                coincidencias.append("subrace")
            if resolved.get("role") and personaje["role_name"] == data.get("role"):
                coincidencias.append("role")

            return {
                "mensaje": "Personaje afín encontrado",
                "personaje": personaje,
                "puntaje_afinidad": int(personaje.get("puntaje_afinidad") or 0),
                "coincidencias": coincidencias,
                "criterio": "origin + category + race + subrace + role",
            }, 200
        finally:
            cur.close()
            conn.close()


game_service = GiroService()


# ================== QUERY HELPERS ==================
def build_filter(params):
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


def query_distinct(select_expr, params):
    joins, where_clause, values = build_filter(params)

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


def query_all_values(table_name, name_column):
    allowed = {
        "origin": "origin_name",
        "category": "category_name",
        "race": "race_name",
        "subrace": "subrace_name",
        "role": "role_name",
        "weapon": "weapon_name",
        "damage_type": "damage_type_name",
        "morality": "morality_name",
        "threat_level": "threat_level_name",
        "tipo_dibujo": "nombre_tipo_dibujo",
    }

    if table_name not in allowed or allowed[table_name] != name_column:
        raise ValueError("tabla o columna no permitida")

    conn = game_service.get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        cur.execute(f"""
            SELECT {name_column} AS valor
            FROM {table_name}
            ORDER BY {name_column} ASC
        """)

        return [row["valor"] for row in cur.fetchall() if row["valor"]]
    finally:
        cur.close()
        conn.close()


# ================== ROUTES ==================
@app.get("/health")
def health():
    return jsonify({"ok": True})


@app.get("/control-juego")
def control_juego():
    return jsonify(game_service.get_control_state())


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


@app.get("/categorias-todas")
def obtener_categorias_todas():
    return jsonify({"categorias": query_all_values("category", "category_name")})


@app.get("/razas-todas")
def obtener_razas_todas():
    return jsonify({"razas": query_all_values("race", "race_name")})


@app.get("/subrazas-todas")
def obtener_subrazas_todas():
    return jsonify({"subrazas": query_all_values("subrace", "subrace_name")})


@app.get("/roles")
def obtener_roles():
    return jsonify({"roles": query_all_values("role", "role_name")})


@app.get("/armas")
def obtener_armas():
    return jsonify({"armas": query_all_values("weapon", "weapon_name")})


@app.get("/tipos-dano")
def obtener_tipos_dano():
    return jsonify({"tipos_dano": query_all_values("damage_type", "damage_type_name")})


@app.get("/moralidades")
def obtener_moralidades():
    return jsonify({"moralidades": query_all_values("morality", "morality_name")})


@app.get("/niveles-amenaza")
def obtener_niveles_amenaza():
    return jsonify({"niveles_amenaza": query_all_values("threat_level", "threat_level_name")})


@app.get("/tipos-dibujo")
def obtener_tipos_dibujo():
    return jsonify({"tipos_dibujo": query_all_values("tipo_dibujo", "nombre_tipo_dibujo")})


@app.get("/personajes-filtrados")
def obtener_personajes_filtrados():
    params = {
        "origin": request.args.get("origin"),
        "category": request.args.get("category"),
        "race": request.args.get("race"),
        "subrace": request.args.get("subrace"),
        "role": request.args.get("role"),
        "weapon": request.args.get("weapon"),
        "damage_type": request.args.get("damage_type"),
        "morality": request.args.get("morality"),
        "threat_level": request.args.get("threat_level"),
    }

    joins, where_clause, values = build_filter(params)

    conn = game_service.get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        cur.execute(f"""
            SELECT
                c.id_character,
                c.character_name,
                o.origin_name,
                cat.category_name,
                r.race_name,
                s.subrace_name,
                ro.role_name,
                w.weapon_name,
                dt.damage_type_name,
                m.morality_name,
                tl.threat_level_name
            FROM characters c
            {joins}
            {where_clause}
            ORDER BY c.character_name ASC
        """, tuple(values))

        return jsonify({"personajes": cur.fetchall()})
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


@app.post("/guardar-ruleta")
def guardar_ruleta():
    data = request.get_json(force=False, silent=True) or {}
    result, status = game_service.register_roulette_result(data)
    return jsonify(result), status


@app.post("/guardar-pregunta")
def guardar_pregunta():
    data = request.get_json(force=False, silent=True) or {}
    result, status = game_service.register_question_result(data)
    return jsonify(result), status

@app.get("/recompensas")
def obtener_recompensas():
    id_sesion = request.args.get("id_sesion")

    if id_sesion:
        try:
            id_sesion = int(id_sesion)
        except ValueError:
            return jsonify({"error": "id_sesion debe ser numérico"}), 400
    else:
        id_sesion = None

    result, status = game_service.get_reward_summary(id_sesion=id_sesion)
    return jsonify(result), status


@app.post("/guardar-recompensa")
def guardar_recompensa():
    data = request.get_json(force=False, silent=True) or {}
    result, status = game_service.grant_reward(data)
    return jsonify(result), status



@app.post("/reiniciar-juego")
def reiniciar_juego():
    data = request.get_json(force=False, silent=True) or {}
    result, status = game_service.reset_game(data)
    return jsonify(result), status



@app.post("/personaje-afin")
def personaje_afin():
    data = request.get_json(force=False, silent=True) or {}
    result, status = game_service.get_affine_character(data)
    return jsonify(result), status

@app.get("/historial")
def ver_historial():
    limit = request.args.get("limit", "5")

    try:
        limit = int(limit)
    except ValueError:
        limit = 5

    limit = max(1, min(limit, 50))

    conn = game_service.get_db_connection()
    cur = conn.cursor(dictionary=True, buffered=True)

    try:
        cur.execute("""
            SELECT
                rr.id_registro_ruleta,
                rr.id_sesion,
                rr.id_usuario,
                rr.id_ruleta,
                rr.nombre_tabla_ruleta,
                rr.fecha_creacion,
                rr.fecha_actualizacion
            FROM registro_ruletas rr
            ORDER BY rr.id_registro_ruleta DESC
            LIMIT %s
        """, (limit,))
        ruletas = cur.fetchall()

        cur.execute("""
            SELECT
                rp.id_registro_pregunta,
                rp.id_sesion,
                rp.id_usuario,
                rp.fecha_creacion,
                rp.fecha_actualizacion,
                rp.id_pregunta,
                rp.id_respuesta,
                rp.id_tipo_dibujo,
                p.texto_pregunta,
                r.texto_respuesta,
                td.nombre_tipo_dibujo
            FROM registro_preguntas rp
            LEFT JOIN pregunta p ON rp.id_pregunta = p.id_pregunta
            LEFT JOIN respuesta r ON rp.id_respuesta = r.id_respuesta
            LEFT JOIN tipo_dibujo td ON rp.id_tipo_dibujo = td.id_tipo_dibujo
            ORDER BY rp.id_registro_pregunta DESC
            LIMIT %s
        """, (limit,))
        preguntas = cur.fetchall()

        return jsonify({
            "registro_ruletas": ruletas,
            "registro_preguntas": preguntas,
        })
    finally:
        cur.close()
        conn.close()


# ================== RUN ==================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True, threaded=True)
    