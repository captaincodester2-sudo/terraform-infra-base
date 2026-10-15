variable "region" {
  type        = string
  description = "Región de AWS donde se desplegarán los recursos"
}

variable "vpc_cidr" {
  type        = string
  description = "Bloque de IPs de la VPC en formato CIDR - 10.0.0.0/16"
}

variable "environment" {
  type        = string
  description = "Nombre del entorno"
}