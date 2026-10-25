variable "bucket_name" {
  type        = string
  description = "Nombre del bucket S3"
}

variable "force_destroy" {
  type        = bool
  description = "Forzar destruccion de bucket S3, limpiando primero su contenido"
}