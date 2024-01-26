locals {
  # Must have bucket versioning enabled first
  bucket_versioning_status = try(aws_s3_bucket_versioning.this[0].versioning_configuration.*.status[0], null)
  enable_versioning_status = lower(local.bucket_versioning_status) == "enabled" ? true : false
  enabled_replication      = var.enable_replication && local.enable_versioning_status
}

resource "aws_s3_bucket_replication_configuration" "this" {
  count  = local.enabled_replication ? 1 : 0
  bucket = aws_s3_bucket.this[0].bucket
  role   = var.replication_role_arn #  aws_iam_role.east_replication.arn

  dynamic "rule" {
    for_each = var.replication_rules == null ? [] : var.replication_rules

    content {
      id       = try(rule.value.id, null)
      priority = try(rule.value.priority, null)
      status   = try(tobool(rule.value.status) ? "Enabled" : "Disabled", "Disabled")

      dynamic "delete_marker_replication" {
        for_each = try(rule.value.delete_marker_replication, null) == null ? [] : ["true"]
        content {
          status = try(tobool(rule.value.delete_marker_replication) ? "Enabled" : "Disabled", "Disabled")
        }
      }

      # see - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-what-is-isnot-replicated.html
      dynamic "existing_object_replication" {
        for_each = try(rule.value.existing_object_replication, null) == null ? [] : ["true"]

        content {
          status = try(tobool(rule.value.existing_object_replication) ? "Enabled" : "Disabled", "Disabled")
        }
      }

      # see - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-add-config.html#replication-config-optional-filter
      dynamic "filter" {
        iterator = filter
        for_each = length(keys(lookup(rule.value, "filter", {}))) > 0 ? [
          lookup(rule.value, "filter", {})
        ] : [
        ]

        content {
          dynamic "and" {
            iterator = and
            for_each = lookup(filter.value, "and", [
            ])

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
        }
      }

      destination {
        bucket = ""
      }

    } # end-of-content

  } # end-of-rule

  depends_on = [aws_s3_bucket_versioning.this]
}
