output "bucket_s3_datalake_arn" {
  description = "ARN del bucket s3"
  value       = aws_s3_bucket.bucket_s3_datalake.arn
}

output "bucket_s3_datalake_name" {
  description = "Nombre del bucket s3"
  value       = aws_s3_bucket.bucket_s3_datalake.bucket
}