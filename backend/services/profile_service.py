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
    
