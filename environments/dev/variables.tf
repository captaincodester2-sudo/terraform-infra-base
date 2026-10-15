variable "region" {
  type        = string
  description = "Región de AWS donde se desplegarán los recursos"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "Bloque de IPs de la VPC en formato CIDR - 10.0.0.0/16"
  default     = "10.0.0.0/16"
}

variable "environment" {
  type        = string
  description = "Nombre del entorno"
  default     = "dev"
}

variable "bucket_name" {
  type        = string
  description = "Nombre del bucket de S3 del data lake de AWS"
  default     = "pochipa-datalake-dev"
}

variable "prefix" {
  type        = string
  description = "Nombre de la carpeta logica perteneciente al bucket S3 del data lake"
  default     = "silver-zone"
}