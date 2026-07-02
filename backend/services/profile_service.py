# ================== PROFILE SERVICE ==================
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


def asegurar_perfil_usuario(cur, id_usuario):
    cur.execute("""
        SELECT
            p.id_perfil,
            p.id_usuario,
            p.apodo,
            p.avatar_key,
            p.pointer_key,
            p.exp_total,
            p.peep_coins,
            p.fecha_creacion,
            p.fecha_actualizacion,
            u.nombre_usuario,
            u.correo,
            u.foto_perfil
        FROM perfil_usuario p
        INNER JOIN usuario u ON p.id_usuario = u.id_usuario
        WHERE p.id_usuario = %s
        LIMIT 1
    """, (id_usuario,))
    perfil = cur.fetchone()

    if perfil:
        return perfil

    usuario = obtener_usuario_por_id(cur, id_usuario)
    if not usuario:
        return None

    apodo = usuario.get("nombre_usuario") or "Peep Player"

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
        SELECT
            p.id_perfil,
            p.id_usuario,
            p.apodo,
            p.avatar_key,
            p.pointer_key,
            p.exp_total,
            p.peep_coins,
            p.fecha_creacion,
            p.fecha_actualizacion,
            u.nombre_usuario,
            u.correo,
            u.foto_perfil
        FROM perfil_usuario p
        INNER JOIN usuario u ON p.id_usuario = u.id_usuario
        WHERE p.id_usuario = %s
        LIMIT 1
    """, (id_usuario,))

    return cur.fetchone()

# ================== PROFILE RESPONSE HELPERS ==================
def calcular_nivel_desde_exp(exp_total):
    exp_total = int(exp_total or 0)
    nivel_actual = (exp_total // 100) + 1
    exp_inicio_nivel = (nivel_actual - 1) * 100
    exp_siguiente_nivel = nivel_actual * 100
    exp_en_nivel = exp_total - exp_inicio_nivel
    progreso_nivel = exp_en_nivel / 100

    return {
        "nivel_actual": nivel_actual,
        "exp_total": exp_total,
        "exp_en_nivel": exp_en_nivel,
        "exp_siguiente_nivel": exp_siguiente_nivel,
        "progreso_nivel": progreso_nivel,
    }


def serializar_perfil_usuario(perfil):
    if not perfil:
        return None

    avatar_key = perfil.get("avatar_key") or "maga"
    pointer_key = perfil.get("pointer_key") or "puntero_clasico"
    exp_total = int(perfil.get("exp_total") or 0)
    peep_coins = int(perfil.get("peep_coins") or 0)
    nivel = calcular_nivel_desde_exp(exp_total)

    return {
        "id_usuario": perfil["id_usuario"],
        "nombre_usuario": perfil.get("nombre_usuario"),
        "correo": perfil.get("correo"),
        "foto_perfil": perfil.get("foto_perfil"),
        "apodo": perfil.get("apodo") or perfil.get("nombre_usuario") or "Peep Player",
        "avatar_key": avatar_key,
        "avatar_asset": f"assets/images/avatars/{avatar_key}.png",
        "pointer_key": pointer_key,
        "pointer_asset": f"assets/images/pointers/{pointer_key}.png",
        "exp_total": exp_total,
        "peep_coins": peep_coins,
        "nivel_actual": nivel["nivel_actual"],
        "exp_en_nivel": nivel["exp_en_nivel"],
        "exp_siguiente_nivel": nivel["exp_siguiente_nivel"],
        "progreso_nivel": nivel["progreso_nivel"],
        "fecha_creacion": str(perfil.get("fecha_creacion")),
        "fecha_actualizacion": str(perfil.get("fecha_actualizacion")),
    }


def serializar_burbuja_usuario(perfil):
    perfil_serializado = serializar_perfil_usuario(perfil)

    if not perfil_serializado:
        return None

    return {
        "id_usuario": perfil_serializado["id_usuario"],
        "apodo": perfil_serializado["apodo"],
        "avatar_key": perfil_serializado["avatar_key"],
        "avatar_asset": perfil_serializado["avatar_asset"],
        "nivel_actual": perfil_serializado["nivel_actual"],
        "peep_coins": perfil_serializado["peep_coins"],
        "exp_total": perfil_serializado["exp_total"],
        "exp_en_nivel": perfil_serializado["exp_en_nivel"],
        "exp_siguiente_nivel": perfil_serializado["exp_siguiente_nivel"],
        "progreso_nivel": perfil_serializado["progreso_nivel"],
    }

# ================== CUSTOMIZATION CONFIG ==================
AVATARES_PERMITIDOS = {"maga", "payaso", "sayajin", "dragon"}
PUNTEROS_PERMITIDOS = {
    "puntero_clasico",
    "puntero_radar",
    "puntero_murcielago",
    "puntero_rayo",
    "puntero_espada",
}


def obtener_opciones_personalizacion(perfil):
    perfil_serializado = serializar_perfil_usuario(perfil)

    if not perfil_serializado:
        return None

    return {
        "id_usuario": perfil_serializado["id_usuario"],
        "avatar_actual": {
            "key": perfil_serializado["avatar_key"],
            "asset": perfil_serializado["avatar_asset"],
        },
        "puntero_actual": {
            "key": perfil_serializado["pointer_key"],
            "asset": perfil_serializado["pointer_asset"],
        },
        "avatares": [
            {
                "key": avatar_key,
                "asset": f"assets/images/avatars/{avatar_key}.png",
                "seleccionado": avatar_key == perfil_serializado["avatar_key"],
            }
            for avatar_key in sorted(AVATARES_PERMITIDOS)
        ],
        "punteros": [
            {
                "key": pointer_key,
                "asset": f"assets/images/pointers/{pointer_key}.png",
                "seleccionado": pointer_key == perfil_serializado["pointer_key"],
            }
            for pointer_key in sorted(PUNTEROS_PERMITIDOS)
        ],
    }


def actualizar_avatar_usuario(cur, id_usuario, avatar_key):
    avatar_key = (avatar_key or "").strip()

    if avatar_key not in AVATARES_PERMITIDOS:
        return {
            "error": "avatar_key no permitido",
            "permitidos": sorted(AVATARES_PERMITIDOS),
        }, 400

    perfil = asegurar_perfil_usuario(cur, id_usuario)

    if not perfil:
        return {"error": "Perfil no encontrado"}, 404

    cur.execute("""
        UPDATE perfil_usuario
        SET avatar_key = %s,
            fecha_actualizacion = CURRENT_TIMESTAMP
        WHERE id_usuario = %s
    """, (
        avatar_key,
        id_usuario,
    ))

    return {
        "mensaje": "Avatar actualizado",
        "id_usuario": id_usuario,
        "avatar_key": avatar_key,
        "avatar_asset": f"assets/images/avatars/{avatar_key}.png",
    }, 200


def actualizar_puntero_usuario(cur, id_usuario, pointer_key):
    pointer_key = (pointer_key or "").strip()

    if pointer_key not in PUNTEROS_PERMITIDOS:
        return {
            "error": "pointer_key no permitido",
            "permitidos": sorted(PUNTEROS_PERMITIDOS),
        }, 400

    perfil = asegurar_perfil_usuario(cur, id_usuario)

    if not perfil:
        return {"error": "Perfil no encontrado"}, 404

    cur.execute("""
        UPDATE perfil_usuario
        SET pointer_key = %s,
            fecha_actualizacion = CURRENT_TIMESTAMP
        WHERE id_usuario = %s
    """, (
        pointer_key,
        id_usuario,
    ))

    return {
        "mensaje": "Puntero actualizado",
        "id_usuario": id_usuario,
        "pointer_key": pointer_key,
        "pointer_asset": f"assets/images/pointers/{pointer_key}.png",
    }, 200

