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
        database=os.getenv("DB_NAME"),
    )

# ================== HEALTH ==================
@app.get("/health")
def health():
    return jsonify({"ok": True})

# ================== GUARDAR GIRO ==================
@app.post("/giro")
def recibir_giro():
    data = request.get_json(silent=True) or {}
    valor = data.get("valor")

    if not valor:
        return jsonify({"error": "valor es requerido"}), 400

    valor = str(valor).strip()

    permitidos = {"1", "2", "3", "4", "5", "Ana", "Deisy", "Diana"}
    if valor not in permitidos:
        return jsonify({"error": "valor inválido"}), 400

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("INSERT INTO PRUEBA_RULETA (valor_flutter) VALUES (%s)", (valor,))
        conn.commit()
    finally:
        cur.close()
        conn.close()

    return jsonify({"valor_guardado": valor})

# ================== HISTORIAL ==================

@app.get("/historial")
def ver_historial():
    conn = get_db_connection()
    cur = conn.cursor(dictionary=True)

    try:
        cur.execute("SELECT * FROM PRUEBA_RULETA ORDER BY id DESC LIMIT 50")
        registros = cur.fetchall()
    finally:
        cur.close()
        conn.close()

    return jsonify(registros)

# ================== CONTADOR ==================

@app.get("/contador")
def contar_giros():
    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("SELECT COUNT(*) FROM PRUEBA_RULETA")
        total = cur.fetchone()[0]
    finally:
        cur.close()
        conn.close()

    return jsonify({"total_giros": total})

# ================== BORRAR HISTORIAL ==================

@app.delete("/historial")
def borrar_historial():
    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("DELETE FROM PRUEBA_RULETA")
        conn.commit()
    finally:
        cur.close()
        conn.close()

    return jsonify({"mensaje": "historial eliminado"})

# ================== RUN ==================
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000, debug=True)
