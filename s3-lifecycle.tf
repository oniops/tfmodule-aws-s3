resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.create && var.enable_bucket_lifecycle && var.lifecycle_rules != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].bucket

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = try(rule.value.id, "five-years-rule")
      status = try(rule.value.status, "Enabled")

      dynamic "filter" {
        for_each = length(try(flatten([rule.value.filter]), [])) == 0 ? [true] : []
        content {
        }
      }

      dynamic "filter" {
        iterator = filter
        for_each = length(keys(lookup(rule.value, "filter", {}))) > 0 ? [lookup(rule.value, "filter", {})] : []

        content {
          dynamic "and" {
            iterator = and
            for_each = lookup(filter.value, "and", [])
            content {
              prefix = lookup(and.value, "prefix", null)
              tags   = lookup(and.value, "tags", null)
            }
          }
          prefix = lookup(filter.value, "prefix", null)
          dynamic "tag" {
            iterator = tag
            for_each = lookup(filter.value, "tag", {})
            content {
              key   = try(tag.key, null)
              value = try(tag.value, null)
            }
          }

          object_size_greater_than = lookup(filter.value, "object_size_greater_than", null)
          object_size_less_than    = lookup(filter.value, "object_size_greater_than", null)
        }
      }

      dynamic "transition" {
        for_each = try(rule.value.itl_tier_days, 0) > 0 ? [true] : []
        content {
          storage_class = "INTELLIGENT_TIERING"
          days          = try(rule.value.itl_tier_days, 365)
        }
      }

      dynamic "transition" {
        for_each = try(rule.value.glacier_days, 0) > 0 ? [true] : []
        content {
          storage_class = "GLACIER"
          days          = try(rule.value.glacier_days, 365)
        }
      }

      dynamic "transition" {
        for_each = try(rule.value.deep_archive_days, 0) > 0 ? [true] : []
        content {
          storage_class = "DEEP_ARCHIVE"
          days          = try(rule.value.deep_archive_days, 730)
        }
      }

      dynamic "expiration" {
        for_each = try(rule.value.expiration_days, 0) > 0 ? [true] : []
        content {
          days = try(rule.value.expiration_days, 1825)
        }
      }

    }
  }

}