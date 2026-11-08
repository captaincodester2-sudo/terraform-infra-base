
resource "aws_kinesisanalyticsv2_application" "sensors" {
  name                   = "${var.environment}-sensors-flink"
  runtime_environment    = "FLINK-1_20"
  service_execution_role = aws_iam_role.flink.arn
  application_mode       = "STREAMING"
  start_application      = true

  application_configuration {

    application_code_configuration {
      code_content_type = "ZIPFILE"

      code_content {
        s3_content_location {
          bucket_arn = var.bucket_arn
          file_key   = aws_s3_object.code.key
        }
      }
    }

    environment_properties {
      property_group {
        property_group_id = "kinesis.analytics.flink.run.options"

        property_map = {
          python  = "main.py"
          jarfile = "lib/pyflink-dependencies.jar"
        }
      }

      property_group {
        property_group_id = "InputStream0"

        property_map = {
          "stream.arn"                 = var.stream_arn
          "aws.region"                 = var.region
          "flink.source.init.position" = "LATEST"
        }
      }
    }

    flink_application_configuration {

      checkpoint_configuration {
        configuration_type            = "CUSTOM"
        checkpointing_enabled         = true
        checkpoint_interval           = var.checkpoint_interval_ms
        min_pause_between_checkpoints = 5000
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "INFO"
        metrics_level      = "APPLICATION"
      }

      parallelism_configuration {
        configuration_type   = "CUSTOM"
        auto_scaling_enabled = false
        parallelism          = var.parallelism
        parallelism_per_kpu  = 1
      }
    }
  }

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink.arn
  }

  depends_on = [aws_iam_role_policy_attachment.flink]
}