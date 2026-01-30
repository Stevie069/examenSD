import paho.mqtt.client as mqtt
import pandas as pd
import joblib
import json
import psycopg2

# --- CONFIGURACIÓN ---
BROKER = "localhost"
TOPIC_REQ = "escuela/predict/request"
TOPIC_RES = "escuela/predict/response"

print("🧠 Iniciando NODO 3: Servicio de Predicción (IA)...")

# 1. CARGAR IA
try:
    model = joblib.load('modelo_final.pkl')
    encoders = joblib.load('codificadores.pkl')
    print("✅ Modelos IA cargados.")
except:
    print("❌ Error: Faltan archivos .pkl")
    exit()

# 2. CONEXIÓN DB (Solo para escribir)
def get_db():
    return psycopg2.connect(host="localhost", port="5435", database="escuela_db", user="admin", password="admin")

# Inicializar tabla si no existe
conn = get_db()
cur = conn.cursor()
cur.execute("""
    CREATE TABLE IF NOT EXISTS predicciones (
        id SERIAL PRIMARY KEY,
        student_data JSONB,
        nota_predicha FLOAT,
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
""")
conn.commit()
conn.close()

# 3. LÓGICA
def on_connect(client, userdata, flags, rc):
    print("✅ Nodo Predicción conectado al Broker.")
    client.subscribe(TOPIC_REQ)

def on_message(client, userdata, msg):
    print(f"📩 Solicitud de predicción recibida.")
    try:
        data = json.loads(msg.payload.decode())
        
        # Preparar datos
        input_data = {
            'age': float(data['age']), 'gender': data['gender'], 'course': data['course'],
            'study_hours': float(data['study_hours']), 'class_attendance': float(data['class_attendance']),
            'internet_access': data['internet_access'], 'sleep_hours': float(data['sleep_hours']),
            'sleep_quality': data['sleep_quality'], 'study_method': data['study_method'],
            'facility_rating': data['facility_rating'], 'exam_difficulty': data['exam_difficulty']
        }
        df_input = pd.DataFrame([input_data])

        # Codificar
        for col, le in encoders.items():
            df_input[col] = df_input[col].map(lambda s: le.transform([s])[0] if s in le.classes_ else 0)

        # Predecir
        pred = float(round(model.predict(df_input)[0], 2))

        # Guardar en BD (Escritura)
        conn = get_db()
        cur = conn.cursor()
        cur.execute("INSERT INTO predicciones (student_data, nota_predicha) VALUES (%s, %s)", (json.dumps(data), pred))
        conn.commit()
        conn.close()

        # Responder
        client.publish(TOPIC_RES, json.dumps({"score": pred}))
        print(f"📤 Predicción enviada: {pred}")

    except Exception as e:
        print(f"❌ Error: {e}")

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.connect(BROKER, 1883, 60)
client.loop_forever()