# Infraestructura base de datos en AWS (Terraform)

Infraestructura base de una plataforma de datos en AWS, definida como código
con Terraform: red privada, roles IAM y estado remoto con locking.

## Qué recursos crea

El `plan` crea **13 recursos**, agrupados en dos módulos:

**Red (`modules/network`)**
- 1 VPC (`10.0.0.0/16` por defecto)
- 2 subnets privadas en zonas de disponibilidad distintas (`us-east-1a` y `us-east-1b`)
- 1 route table privada, asociada a las dos subnets
- 1 S3 Gateway Endpoint, asociado a esa route table, para llegar a S3 sin
  pasar por internet ni pagar un NAT Gateway

Las subnets no tienen ruta a un Internet Gateway, por lo que no son accesibles
desde internet.

**Identidad (`modules/identity`)**
- Rol de ejecución para servicios de procesamiento de datos (Lambda), con una
  policy que permite únicamente `s3:ListBucket`, `s3:GetObject` y
  `s3:PutObject` sobre un prefijo específico del bucket del data lake
- Rol de auditoría del plano de control, con una policy de solo lectura
  (IAM, EC2 y configuración del bucket), sin acceso al contenido de los objetos

## Estructura del repositorio

```
.
├── environments/
│   └── dev/            # Punto de entrada: backend, provider y llamada a los módulos
├── modules/
│   ├── network/        # VPC, subnets, route table y S3 Gateway Endpoint
│   └── identity/       # Roles IAM, policies y attachments
├── PLAN_OUTPUT.md      # Salida de un terraform plan exitoso
└── README.md
```

Todos los comandos de Terraform se ejecutan desde `environments/dev`.

## Requisitos previos

- Terraform `>= 1.16.4`
- AWS CLI instalada y configurada (`aws configure`) con credenciales que
  puedan crear los recursos descritos arriba
- Una cuenta de AWS

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

El `plan` tiene que terminar con `Plan: 13 to add, 0 to change, 0 to destroy`.
Un ejemplo completo está en [PLAN_OUTPUT.md](PLAN_OUTPUT.md).

Para eliminar todo lo creado: `terraform destroy` (desde `environments/dev`).
El bucket y la tabla del backend no se borran con ese comando.

## Variables

Se definen en `environments/dev/variables.tf`. Los módulos no tienen valores
por defecto: los reciben desde `dev`.

| Variable |