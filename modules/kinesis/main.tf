data "aws_kms_key" "key_decrypt" {
  key_id = "alias/aws/kinesis"
}

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
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = [aws_cloudwatch_log_stream.log_stream.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [data.aws_kms_key.key_decrypt.arn]
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/kinesisfirehose/${var.environment}-ingestion-firehose"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "DestinationDelivery"
  log_group_name = aws_cloudwatch_log_group.log_group.name
}

resource "aws_kinesis_firehose_delivery_stream" "ingestion" {
  name        = "${var.environment}-ingestion-firehose"
  destination = "extended_s3"
  depends_on  = [aws_iam_role_policy_attachment.firehose_access]

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.ingestion.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.bucket_arn

    buffering_size     = 5
    buffering_interval = 60

    prefix              = "${var.firehose_prefix}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "${var.firehose_prefix}/type=!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.log_group.name
      log_stream_name = aws_cloudwatch_log_stream.log_stream.name
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "write_throughput_exceeded" {
  alarm_name          = "${var.environment}-WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  metric_name         = "WriteProvisionedThroughputExceeded"
  dimensions          = { StreamName = aws_kinesis_stream.ingestion.name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "read_throughput_exceeded" {
  alarm_name          = "${var.environment}-ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  metric_name         = "ReadProvisionedThroughputExceeded"
  dimensions          = { StreamName = aws_kinesis_stream.ingestion.name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}