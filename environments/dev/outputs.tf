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

output "stream_arn" {
  description = "ARN del stream"
  value       = module.kinesis.stream_arn
}

output "stream_name" {
  description = "Nombre del stream"
  value       = module.kinesis.stream_name
}

output "bucket_s3_datalake_arn" {
  description = "ARN del bucket s3"
  value       = module.storage.bucket_s3_datalake_arn
}

output "bucket_s3_datalake_name" {
  description = "Nombre del bucket s3"
  value       = module.storage.bucket_s3_datalake_name
}