output "stream_arn" {
  description = "ARN del stream"
  value       = aws_kinesis_stream.ingestion.arn
}

output "stream_name" {
  description = "Nombre del stream"
  value       = aws_kinesis_stream.ingestion.name
}