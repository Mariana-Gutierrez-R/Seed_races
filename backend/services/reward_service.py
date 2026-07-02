# ================== REWARD SERVICE ==================
def add_profile_rewards(cur, id_usuario, exp=0, coins=0):
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
