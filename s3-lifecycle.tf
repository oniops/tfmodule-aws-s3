resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.create_bucket && var.enable_bucket_lifecycle && var.lifecycle_rules != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].bucket

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = try(rule.value.id, "five-years-rule")
      status = try(rule.value.status, "Enabled")

      dynamic "transition" {
        for_each = try(rule.value.glacier_days, 0) > 0 ? ["true"] : []
        content {
          storage_class = "GLACIER"
          days          = try(rule.value.glacier_days, 365)
        }
      }

      dynamic "transition" {
        for_each = try(rule.value.deep_archive_days, 0) > 0 ? ["true"] : []
        content {
          storage_class = "DEEP_ARCHIVE"
          days          = try(rule.value.deep_archive_days, 730)
        }
      }

      dynamic "expiration" {
        for_each = try(rule.value.expiration_days, 0) > 0 ? ["true"] : []
        content {
          days = try(rule.value.expiration_days, 1825)
        }
      }

    }
  }

}