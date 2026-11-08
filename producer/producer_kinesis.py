import json
import os
import random
import time
from datetime import datetime, timezone

import boto3

# Configuración por variables de entorno, con valores por defecto
STREAM_NAME = os.environ.get("KINESIS_STREAM", "dev-ingestion-stream")
REGION = os.environ.get("AWS_REGION", "us-east-1")
MENSAJES_POR_SEGUNDO = 5

kinesis = boto3.client("kinesis", region_name=REGION)


def generar_medicion():
    """Una medición de un sensor, con el formato que espera tabla_kinesis.sql."""
    ahora = datetime.now(timezone.utc)
    return {
        "sensor_id": f"sensor-0{random.randint(1, 5)}",
        "temperature": round(random.uniform(10, 35), 1),
        "humidity": round(random.uniform(30, 90), 1),
        "air_quality_index": random.randint(0, 300),
        # ISO-8601 en UTC terminando en Z, con milisegundos
        "event_time": ahora.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z",
    }


def main():
    enviados = 0
    print(f"Enviando a {STREAM_NAME} ({REGION}). Ctrl+C para cortar.")
    try:
        while True:
            medicion = generar_medicion()
            kinesis.put_record(
                StreamName=STREAM_NAME,
                Data=json.dumps(medicion).encode("utf-8"),
                # La clave varía por sensor para repartir entre shards
                PartitionKey=medicion["sensor_id"],
            )
            enviados += 1
            if enviados % 50 == 0:
                print(f"{enviados} mensajes enviados. Último: {medicion}")
            time.sleep(1 / MENSAJES_POR_SEGUNDO)
    except KeyboardInterrupt:
        print(f"\nCortado. Total enviados: {enviados}")


if __name__ == "__main__":
    main()