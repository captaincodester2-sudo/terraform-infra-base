data "aws_caller_identity" "current" {}

resource "aws_iam_role" "data_processing" {
  name = "${var.environment}-data-processing-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_data_access" {
  name = "${var.environment}-s3-data-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Resource = [
        "arn:aws:s3:::${var.bucket_name}"
      ]
      Action = [
        "s3:ListBucket"
      ]
      },
      {
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/${var.prefix}/*"
        ]
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "data_processing_s3" {
  role       = aws_iam_role.data_processing.name
  policy_arn = aws_iam_policy.s3_data_access.arn
}

resource "aws_iam_role" "audit_readonly" {
  name = "${var.environment}-control-plane-audit-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "audit_readonly_access" {
  role       = aws_iam_role.audit_readonly.name
  policy_arn = aws_iam_policy.audit_readonly_policy.arn
}

resource "aws_iam_policy" "audit_readonly_policy" {
  name = "${var.environment}-audit-readonly-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:ListRoles"
        ]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeVpcs", "ec2:DescribeSubnets"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetBucketPolicy", "s3:GetEncryptionConfiguration"]
        Resource = ["arn:aws:s3:::${var.bucket_name}"]
      }
    ]
  })
}