import os

from pyflink.table import EnvironmentSettings, TableEnvironment

IS_LOCAL = os.environ.get("IS_LOCAL") == "true"

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
table_env = TableEnvironment.create(settings)


def open_file(file):
    ruta = os.path.join(BASE_DIR, file)
    with open(ruta, "r") as f:
        contenido = f.read()
    return contenido


if IS_LOCAL:
    archivo_origen = "tabla.sql"
else:
    archivo_origen = "tabla_kinesis.sql"

table_env.execute_sql(open_file(archivo_origen))
table_env.execute_sql(open_file("destino.sql"))
resultado = table_env.execute_sql(open_file("consulta.sql"))

if IS_LOCAL:
    resultado.wait()