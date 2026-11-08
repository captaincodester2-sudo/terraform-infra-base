# Logs de la aplicación en CloudWatch. Ahí se ven los resultados que imprime
# el conector "print" y los errores del job.
resource "aws_cloudwatch_log_group" "flink" {
  name              = "/aws/kinesis-analytics/${var.environment}-sensors-flink"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "flink" {
  name           = "application"
  log_group_name = aws_cloudwatch_log_group.flink.name
}
