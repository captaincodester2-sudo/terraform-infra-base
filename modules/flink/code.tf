
data "archive_file" "app" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/build/flink-app.zip"

  excludes = [
    "Dockerfile.local",
    ".dockerignore",
    "capturas",
    "__pycache__",
    "target",
    "src",
    "assembly",
    "pom.xml",
    "dependency-reduced-pom.xml",
  ]
}

resource "aws_s3_object" "code" {
  bucket = var.bucket_name
  key    = "${var.code_prefix}/flink-app.zip"
  source = data.archive_file.app.output_path

  etag = data.archive_file.app.output_md5
}
