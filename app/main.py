import json
import os

from pyflink.table import EnvironmentSettings, TableEnvironment

# En local (IS_LOCAL=true) usa datos falsos y espera. En AWS lee de Kinesis.
IS_LOCAL = os.environ.get("IS_LOCAL") == "true"

# Carpeta donde está este archivo: los .sql se buscan acá, sin importar
# desde dónde se ejecute el programa.
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# En Managed Flink, el servicio escribe las propiedades de la aplicación
# (las que define Terraform) en este archivo.
PROPERTIES_FILE = "/etc/flink/application_properties.json"

settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
table_env = TableEnvironment.create(settings)


def open_file(file):
    ruta = os.path.join(BASE_DIR, file)
    with open(ruta, "r") as f:
        contenido = f.read()
    return contenido


def get_property_group(group_id):
    """Devuelve las propiedades de un grupo definido en Terraform."""
    with open(PROPERTIES_FILE, "r") as f:
        groups = json.load(f)
    for group in groups:
        if group["PropertyGroupId"] == group_id:
            return group["PropertyMap"]
    raise ValueError(f"No existe el grupo de propiedades {group_id}")


# Tabla de origen según dónde corre
if IS_LOCAL:
    table_env.execute_sql(open_file("tabla.sql"))
else:
    props = get_property_group("InputStream0")
    sql_origen = open_file("tabla_kinesis.sql").format(
        stream_arn=props["stream.arn"],
        region=props["aws.region"],
        init_position=props.get("flink.source.init.position", "LATEST"),
    )
    table_env.execute_sql(sql_origen)

table_env.execute_sql(open_file("destino.sql"))
resultado = table_env.execute_sql(open_file("consulta.sql"))

# Solo en local el programa se queda esperando
if IS_LOCAL:
    resultado.wait()
