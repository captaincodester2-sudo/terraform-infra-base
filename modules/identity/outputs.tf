output "data_processing_role_arn" {
  description = "ARN del rol iam data_processing"
  value       = aws_iam_role.data_processing.arn
}

output "audit_readonly_role_arn" {
  description = "ARN del rol iam audit_readonly"
  value       = aws_iam_role.audit_readonly.arn
}