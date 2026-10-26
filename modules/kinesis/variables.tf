variable "shard_count" {
  type        = number
  description = "Cantidad de shards del stream - Se acepta 1MB/s por shard"
}

variable "environment" {
  type        = string
  description = "Nombre del entorno"
}

variable "bucket_arn" {
  type        = string
  description = "ARN del bucket S3 - Viene de modules/storage"
}

variable "firehose_prefix" {
  type        = string
  description = "Nombre de la carpeta perteneciente al bucket S3 del firehose en donde almacena datos crudos"
}