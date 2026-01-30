# 🎓 Sistema Distribuido de Predicción de Rendimiento Académico

Este proyecto es un **Sistema Distribuido** basado en microservicios que utiliza **Inteligencia Artificial** para predecir la nota de un examen basándose en múltiples variables estudiantiles. La comunicación entre todos los componentes se realiza de forma asíncrona mediante el protocolo **MQTT**.



## 🏗️ Arquitectura del Sistema (5 Nodos)

El sistema está desacoplado en 5 nodos independientes para garantizar escalabilidad y robustez:

1.  **Nodo 1: Broker (Mosquitto):** El orquestador de mensajes que utiliza el patrón Publicador/Suscriptor.
2.  **Nodo 2: Base de Datos (PostgreSQL):** Almacén persistente que guarda los datos de entrada y los resultados de las predicciones.
3.  **Nodo 3: Microservicio de Predicción (IA):** Servicio en Python que carga un modelo de `LinearRegression` y procesa las solicitudes de cálculo.
4.  **Nodo 4: Microservicio de Historial:** Servicio en Python especializado en la lectura y recuperación de datos históricos desde la DB.
5.  **Nodo 5: Cliente Móvil (Flutter):** Aplicación multiplataforma que permite al usuario interactuar con el sistema en tiempo real.

## 🛠️ Tecnologías Utilizadas

* **Lenguajes:** Dart (Flutter), Python 3.10.
* **IA/ML:** Scikit-Learn, Pandas, Joblib.
* **Comunicación:** Protocolo MQTT (Mosquitto).
* **Base de Datos:** PostgreSQL 13.
* **Virtualización:** Docker & Docker Compose.

## 🚀 Instalación y Uso

### 1. Requisitos Previos
* Docker y Docker Compose instalados.
* Python 3.10+ con las librerías: `paho-mqtt`, `pandas`, `scikit-learn`, `joblib`, `psycopg2-binary`.
* Flutter SDK instalado.

### 2. Levantar Infraestructura
Desde la raíz del proyecto, inicia el Broker y la Base de Datos:
```bash
docker-compose up -d
