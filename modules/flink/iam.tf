
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flink" {
  name               = "${var.environment}-flink-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "flink" {
  statement {
    sid       = "ReadCode"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["${var.bucket_arn}/${aws_s3_object.code.key}"]
  }

  statement {
    sid = "ReadStream"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:DescribeStreamSummary",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator",
      "kinesis:ListShards",
    ]
    resources = [var.stream_arn]
  }

  statement {
    sid       = "DecryptStream"
    actions   = ["kms:Decrypt"]
    resources = [var.kms_key_arn]
  }

  statement {
    sid       = "WriteLogs"
    actions   = ["logs:PutLogEvents", "logs:DescribeLogStreams"]
    resources = ["${aws_cloudwatch_log_group.flink.arn}:*"]
  }

  statement {
    sid       = "DescribeLogGroups"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "flink" {
  name   = "${var.environment}-flink-execution-policy"
  policy = data.aws_iam_policy_document.flink.json
}

resource "aws_iam_role_policy_attachment" "flink" {
  role       = aws_iam_role.flink.name
  policy_arn = aws_iam_policy.flink.arn
}
