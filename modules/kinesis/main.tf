resource "aws_kinesis_stream" "ingestion" {
  name            = "${var.environment}-ingestion-stream"
  shard_count     = var.shard_count
  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "firehose" {
  name = "${var.environment}-firehose-delivery-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_access" {
  role       = aws_iam_role.firehose.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_iam_policy" "firehose_policy" {
  name = "${var.environment}-firehose-role-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:ListShards"
        ]
        Resource = [aws_kinesis_stream.ingestion.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:GetBucketLocation"
        ]
        Resource = [
          var.bucket_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ]
        Resource = [
          "${var.bucket_arn}/${var.firehose_prefix}/*"
        ]
      }
    ]
  })
}