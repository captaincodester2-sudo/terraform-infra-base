output "vpc_id" {
  description = "ID de la VPC"
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "Lista de los IDs de las subnets privadas"
  value       = module.network.private_subnet_ids
}

output "data_processing_role_arn" {
  description = "ARN del rol iam data_processing"
  value       = module.identity.data_processing_role_arn
}

output "audit_readonly_role_arn" {
  description = "ARN del rol iam audit_readonly"
  value       = module.identity.audit_readonly_role_arn
}