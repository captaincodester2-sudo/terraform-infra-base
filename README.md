# Infraestructura de datos en AWS (Terraform)

Infraestructura base de una plataforma de datos en AWS, definida como código
con Terraform: red privada, roles IAM, estado remoto con locking y una
ingesta de datos en tiempo real (Kinesis → Firehose → S3).

## Qué recursos crea

El `plan` crea **25 recursos**, agrupados en cuatro módulos:

**Red (`modules/network`)** - 7 recursos
- 1 VPC (`10.0.0.0/16` por defecto)
- 2 subnets privadas en zonas de disponibilidad distintas (`us-east-1a` y `us-east-1b`)
- 1 route table privada, asociada a las dos subnets
- 1 S3 Gateway Endpoint, asociado a esa route table, para llegar a S3 sin
  pasar por internet ni pagar un NAT Gateway

Las subnets no tienen ruta a un Internet Gateway, por lo que no son accesibles
desde internet.

**Identidad (`modules/identity`)** - 6 recursos
- Rol de ejecución para servicios de procesamiento de datos (Lambda), con una
  policy que permite únicamente `s3:ListBucket`, `s3:GetObject` y
  `s3:PutObject` sobre un prefijo específico del bucket del data lake
- Rol de auditoría del plano de control, con una policy de solo lectura
  (IAM, EC2 y configuración del bucket), sin acceso al contenido de los objetos

**Almacenamiento (`modules/storage`)** - 3 recursos
- 1 bucket de S3 para el data lake (`pochipa-datalake-dev`)
- Cifrado en reposo con AES256
- Bloqueo de todo acceso público

**Ingesta (`modules/kinesis`)** - 9 recursos
- 1 Kinesis Data Stream en modo provisionado, con 2 shards y cifrado KMS
  (`alias/aws/kinesis`)
- 1 Firehose que lee del stream y guarda los datos en el bucket, dentro de
  `bronze-zone/ingesta/`, separados por año, mes y día. Junta los datos
  hasta 5 MB o 60 segundos, lo que pase primero
- 1 rol IAM para Firehose, con una policy de mínimo privilegio: leer del
  stream, escribir en ese prefijo del bucket, escribir logs y usar la clave KMS
- 1 log group y 1 log stream de CloudWatch para ver los errores de Firehose
- 2 alarmas de CloudWatch que avisan si se supera el throughput de escritura
  o de lectura del stream

## Estructura del repositorio

```
.
├── environments/
│   └── dev/            # Punto de entrada: backend, provider y llamada a los módulos
├── modules/
│   ├── network/        # VPC, subnets, route table y S3 Gateway Endpoint
│   ├── identity/       # Roles IAM, policies y attachments
│   ├── storage/        # Bucket S3 del data lake
│   └── kinesis/        # Kinesis Data Stream, Firehose, rol y alarmas
├── PLAN_OUTPUT.md      # Salida de un terraform plan exitoso
├── EVIDENCIA.md        # Prueba de que la ingesta funciona
└── README.md
```

Todos los comandos de Terraform se ejecutan desde `environments/dev`.

## Requisitos previos

- Terraform `>= 1.16.4`
- AWS CLI instalada y configurada (`aws configure`) con credenciales que
  puedan crear los recursos descritos arriba
- Una cuenta de AWS en **plan Paid**. Con el plan gratuito, Kinesis falla con
  el error `SubscriptionRequiredException`

## Bootstrap del backend

El estado de Terraform se guarda en S3 con locking en DynamoDB. Ambos recursos
tienen que existir **antes** del primer `terraform init`, y Terraform no los
crea. Se crean una sola vez.

**1. Bucket del estado**

El nombre tiene que ser único globalmente en AWS. Si desplegás en otra cuenta,
elegí otro nombre y actualizalo también en el bloque `backend` de
`environments/dev/main.tf`.

```bash
BUCKET="pochipa-tfstate-dev"

aws s3api create-bucket --bucket "$BUCKET" --region us-east-1

aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

En regiones distintas de `us-east-1`, `create-bucket` necesita además
`--create-bucket-configuration LocationConstraint=<región>`.

**2. Tabla de locking**

La clave de partición tiene que llamarse exactamente `LockID` y ser de tipo
String: es el nombre que Terraform espera.

```bash
aws dynamodb create-table \
  --table-name pochipa-tfstate-locks-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Cómo desplegar

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

El `plan` tiene que terminar con `Plan: 25 to add, 0 to change, 0 to destroy`.
Un ejemplo del plan está en [PLAN_OUTPUT.md](PLAN_OUTPUT.md).

Para eliminar todo lo creado: `terraform destroy` (desde `environments/dev`).
El bucket y la tabla del backend no se borran con ese comando.

> **Cuidado con los costos:** Kinesis cobra por cada shard mientras exista, aunque
> no le mandes datos. Conviene correr `terraform destroy` apenas termines de
> probar.

## Cómo probar la ingesta

Con todo desplegado, se manda un dato de prueba al stream:

```bash
aws kinesis put-record \
  --stream-name dev-ingestion-stream \
  --partition-key "user-001" \
  --data '{"sensor_id":"s-001","temperature":22.5}' \
  --cli-binary-format raw-in-base64-out \
  --region us-east-1
```

Si salió bien, devuelve el `ShardId` y un `SequenceNumber`.

Firehose junta los datos durante unos 60 segundos antes de guardarlos. Pasado
ese tiempo, el archivo aparece en el bucket:

```bash
aws s3 ls s3://pochipa-datalake-dev/ --recursive
```

La salida real de esta prueba, con el archivo generado por Firehose, está en
[EVIDENCIA.md](EVIDENCIA.md).

## Variables

Se definen en `environments/dev/variables.tf`. Los módulos no tienen valores
por defecto: los reciben desde `dev`.

| Variable | Qué es | Valor por defecto |
|---|---|---|
| `region` | Región de AWS | `us-east-1` |
| `environment` | Nombre del entorno, se usa en los nombres de los recursos | `dev` |
| `vpc_cidr` | Rango de IPs de la VPC | `10.0.0.0/16` |
| `bucket_name` | Nombre del bucket del data lake (único en todo AWS) | `pochipa-datalake-dev` |
| `prefix` | Carpeta del bucket donde el rol de procesamiento puede leer y escribir | `silver-zone` |
| `force_destroy` | Permite borrar el bucket aunque tenga archivos | `true` |
| `shard_count` | Cantidad de shards del stream | `2` |
| `firehose_prefix` | Carpeta del bucket donde Firehose guarda los datos | `bronze-zone/ingesta` |