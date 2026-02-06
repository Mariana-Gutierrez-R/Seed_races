from flask import Flask, request, jsonify
import mysql.connector

app = Flask(__name__)

# 🔌 MySQL connection
def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="FamiliaGR2025*",
        database="seed_races"
    )

# ✅ Ensure table has columns to store text too (safe: tries once)
def ensure_schema():
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        # Add these columns only if they don't exist (MySQL 8 doesn't support IF NOT EXISTS for ADD COLUMN in all setups)
        # So we do a simple try/except per column.
        try:
            cur.execute("ALTER TABLE PRUEBA_RULETA ADD COLUMN Texto_flutter VARCHAR(100) NULL;")
        except:
            pass

        try:
            cur.execute("ALTER TABLE PRUEBA_RULETA ADD COLUMN Tipo VARCHAR(20) NOT NULL DEFAULT 'numero';")
        except:
            pass

        conn.commit()
    finally:
        cur.close()
        conn.close()

ensure_schema()

@app.get("/health")
def health():
    return jsonify({"ok": True})

# 🧮 NUMBERS: receive number 1..5, multiply by 4, save
@app.post("/numero")
def recibir_numero():
    data = request.get_json(silent=True) or {}
    numero = data.get("numero")

    if numero is None:
        return jsonify({"error": "numero is required"}), 400

    try:
        numero = int(numero)
    except:
        return jsonify({"error": "numero must be an integer"}), 400

    if numero < 1 or numero > 5:
        return jsonify({"error": "numero must be between 1 and 5"}), 400

    resultado = numero * 4

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO PRUEBA_RULETA (Numero_flutter, Numero_ejecucion, Tipo, Texto_flutter) VALUES (%s, %s, %s, %s)",
        (numero, resultado, "numero", None)
    )
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"numero_recibido": numero, "resultado": resultado})

# 🔤 TEXT: receive name (Ana/Daisy/Diana), save
@app.post("/texto")
def recibir_texto():
    data = request.get_json(silent=True) or {}
    nombre = data.get("nombre")

    if not nombre:
        return jsonify({"error": "nombre is required"}), 400

    nombre = str(nombre).strip()

    allowed = {"Ana", "Daisy", "Diana"}
    if nombre not in allowed:
        return jsonify({"error": "nombre must be one of: Ana, Daisy, Diana"}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    # For text spins: Numero_flutter can be NULL, Numero_ejecucion can be 0
    cur.execute(
        "INSERT INTO PRUEBA_RULETA (Numero_flutter, Numero_ejecucion, Tipo, Texto_flutter) VALUES (%s, %s, %s, %s)",
        (None, 0, "texto", nombre)
    )
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"nombre_recibido": nombre})

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000, debug=True)
