# Evidencia - Pre-entrega 2

Prueba de la ingesta: mando un dato con la AWS CLI a Kinesis, Firehose lo toma y lo guarda en S3.

Región: us-east-1. Entorno: dev. (El ID de mi cuenta de AWS lo reemplacé por `<ACCOUNT_ID>`.)

## 1. Terraform apply

Hice `terraform apply` desde `environments/dev` y se crearon los recursos del stream y de Firehose:

```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

## 2. Mandar un dato al stream

```bash
aws kinesis put-record \
  --stream-name dev-ingestion-stream \
  --partition-key "user-001" \
  --data '{"sensor_id":"s-001","temperature":22.5}' \
  --cli-binary-format raw-in-base64-out \
  --region us-east-1
```

Respuesta:

```json
{
    "ShardId": "shardId-000000000000",
    "SequenceNumber": "49679624229476933169030243327259011417478885962088972290",
    "EncryptionType": "KMS"
}
```

El stream aceptó el dato.

## 3. Archivo que generó Firehose en S3

```bash
aws s3 ls s3://pochipa-datalake-dev/ --recursive
```

```
2026-10-26 10:06:40         40 bronze-zone/ingesta/year=2026/month=10/day=26/dev-ingestion-firehose-1-2026-10-26-10-05-39-cbda9621-1eca-41e2-a546-5430116bb3c8
```

Firehose guardó el archivo en `bronze-zone/ingesta/` con la fecha en la ruta.

Para ver qué tiene adentro:

```bash
aws s3 cp s3://pochipa-datalake-dev/bronze-zone/ingesta/year=2026/month=10/day=26/dev-ingestion-firehose-1-2026-10-26-10-05-39-cbda9621-1eca-41e2-a546-5430116bb3c8 -
```

```
{"sensor_id":"s-001","temperature":22.5}
```

Es el mismo dato que mandé.

## 4. Estado de los recursos

Con `aws kinesis describe-stream-summary` y `aws firehose describe-delivery-stream` verifiqué que los dos están en estado `ACTIVE`. El stream tiene 2 shards y está cifrado con KMS.

## 5. Limpieza

Cuando terminé de probar corrí `terraform destroy` desde `environments/dev` para no dejar nada corriendo (Kinesis cobra por shard mientras exista):

```
Plan: 0 to add, 0 to change, 25 to destroy.
...
Destroy complete! Resources: 25 destroyed.
```

Después verifiqué que no quedaron streams:

```bash
aws kinesis list-streams --region us-east-1
```

La lista salió vacía.