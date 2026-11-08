variable "environment" {
  type        = string
  description = "Nombre del entorno (dev, prod). Se usa en los nombres de los recursos."
}

variable "region" {
  type        = string
  description = "Región de AWS donde está el stream de Kinesis."
}

variable "stream_name" {
  type        = string
  description = "Nombre del Kinesis Data Stream del que lee Flink."
}

variable "stream_arn" {
  type        = string
  description = "ARN del Kinesis Data Stream (para el permiso de lectura)."
}

variable "kms_key_arn" {
  type        = string
  description = "ARN de la clave KMS que cifra el stream (para descifrar al leer)."
}

variable "bucket_name" {
  type        = string
  description = "Nombre del bucket donde se sube el zip de la aplicación."
}

variable "bucket_arn" {
  type        = string
  description = "ARN del bucket donde se sube el zip de la aplicación."
}

variable "code_prefix" {
  type        = string
  description = "Carpeta dentro del bucket donde se guarda el zip (por ejemplo flink/code)."
}

variable "source_dir" {
  type        = string
  description = "Ruta a la carpeta app/ con el código de Flink y el JAR del conector."
}

variable "parallelism" {
  type        = number
  description = "Paralelismo de la aplicación (1 = una sola tarea, el mínimo costo)."
}

variable "checkpoint_interval_ms" {
  type        = number
  description = "Cada cuántos milisegundos se hace un checkpoint (60000 = 1 minuto)."
}
