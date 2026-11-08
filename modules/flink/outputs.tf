output "application_name" {
  description = "Nombre de la aplicación de Managed Flink."
  value       = aws_kinesisanalyticsv2_application.sensors.name
}

output "log_group_name" {
  description = "Log group de CloudWatch donde se ven los resultados."
  value       = aws_cloudwatch_log_group.flink.name
}
