# Map to s3-target-bucket for access logs
resource "aws_s3_bucket_logging" "this" {
  count         = local.enabled_s3_bucket_logging ? 1 : 0
  bucket        = local.bucket_name
  target_bucket = var.s3_logs_bucket
  target_prefix = "logs/${local.bucket_name}/"
}
