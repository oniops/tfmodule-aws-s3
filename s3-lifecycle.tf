resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.create && var.enable_bucket_lifecycle && length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket                                 = aws_s3_bucket.this[0].bucket
  transition_default_minimum_object_size = var.transition_default_minimum_object_size

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.key
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Always render a filter block; an empty filter applies the rule to every object.
      filter {
        prefix                   = rule.value.filter.prefix
        object_size_greater_than = rule.value.filter.object_size_greater_than
        object_size_less_than    = rule.value.filter.object_size_less_than

        dynamic "tag" {
          for_each = rule.value.filter.tag[*]
          content {
            key   = tag.value.key
            value = tag.value.value
          }
        }

        dynamic "and" {
          for_each = rule.value.filter.and[*]
          content {
            prefix                   = and.value.prefix
            tags                     = and.value.tags
            object_size_greater_than = and.value.object_size_greater_than
            object_size_less_than    = and.value.object_size_less_than
          }
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          storage_class = transition.key
          days          = transition.value
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days[*]
        content {
          days = expiration.value
        }
      }

      # Noncurrent versions require bucket versioning.
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions
        content {
          storage_class   = noncurrent_version_transition.key
          noncurrent_days = noncurrent_version_transition.value
        }
      }

      # Delete incomplete multipart uploads N days after initiation (not allowed with tag-based filters).
      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload_days[*]
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days[*]
        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }
    }
  }
}
