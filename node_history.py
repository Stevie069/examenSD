import paho.mqtt.client as mqtt
import json
import psycopg2
from datetime import datetime

# --- CONFIGURACIÓN ---
BROKER = "localhost"
TOPIC_REQ = "escuela/history/request"
TOPIC_RES = "escuela/history/response"

print("📜 Iniciando NODO 4: Servicio de Historial (DB Reader)...")

# 1. CONEXIÓN DB (Solo para leer)
def get_db():
    return psycopg2.connect(host="localhost", port="5435", database="escuela_db", user="admin", password="admin")

# 2. LÓGICA
def on_connect(client, userdata, flags, rc):
    print("✅ Nodo Historial conectado al Broker.")
    client.subscribe(TOPIC_REQ)

def on_message(client, userdata, msg):
    print(f"📩 Solicitud de historial recibida.")
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT nota_predicha, fecha, student_data FROM predicciones ORDER BY id DESC LIMIT 10")
        rows = cur.fetchall()
        conn.close()

        historial = []
        for r in rows:
            d = r[2] # El JSON guardado en student_data
            historial.append({
                "score": r[0],
                "date": r[1].strftime("%H:%M"),
                "study": d.get('study_hours', 0),
                "attend": d.get('class_attendance', 0)
            })
        
        client.publish(TOPIC_RES, json.dumps(historial))
        print("📤 Historial enviado.")

    except Exception as e:
        print(f"❌ Error leyendo DB: {e}")

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.connect(BROKER, 1883, 60)
client.loop_forever()