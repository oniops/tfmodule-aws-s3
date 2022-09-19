# Map to s3-target-bucket for access logs
resource "aws_s3_bucket_logging" "this" {
  count         = local.enabled_s3_bucket_logging ? 1 : 0
  bucket        = var.bucket
  target_bucket = var.s3_logs_bucket
  target_prefix = "logs/"
}

data "aws_iam_policy_document" "log" {
  statement {
    sid     = "S3AccessLogs"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      format("%s/*", var.s3_logs_bucket_arn)
    ]
    principals {
      type        = "AWS"
      identifiers = ["*",]
    }
  }
}

resource "aws_s3_bucket_policy" "log" {
  count  = local.enabled_s3_bucket_logging ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.log.json
}
