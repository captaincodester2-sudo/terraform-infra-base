variable "environment" {
  type        = string
  description = "Nombre del entorno"
}

variable "bucket_name" {
  type        = string
  description = "Nombre del bucket de S3 del data lake"
}

variable "prefix" {
  type        = string
  description = "Nombre de la carpeta logica perteneciente al bucket S3 del data lake - Ejemplo: silver-zone"
}