resource "aws_s3_bucket" "bucket_s3_datalake" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_s3_datalake_crypto" {
  bucket = aws_s3_bucket.bucket_s3_datalake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_s3_datalake_security" {
  bucket                  = aws_s3_bucket.bucket_s3_datalake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}