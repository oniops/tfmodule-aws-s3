resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.create_bucket && var.enable_bucket_lifecycle && var.lifecycle_rules != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].bucket

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = try(rule.value.id, "five-years-rule")
      status = try(rule.value.status, "Enabled")

      # 1 years
      transition {
        storage_class = "GLACIER"
        days          = try(rule.value.glacier_days, 365)
      }

      # 2 years
      transition {
        storage_class = "DEEP_ARCHIVE"
        days          = try(rule.value.deep_archive_days, 730)
      }

      # 5 years
      expiration {
        days = try(rule.value.expiration_days, 1825)
      }
    }
  }

}