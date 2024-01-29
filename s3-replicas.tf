locals {
  # Must have bucket versioning enabled first
  bucket_versioning_status = try(aws_s3_bucket_versioning.this[0].versioning_configuration.*.status[0], null)
  enable_versioning_status = try(lower(local.bucket_versioning_status), "") == "enabled" ? true : false
  enabled_replication      = var.enable_replication && local.enable_versioning_status
  create_replication_role  = local.enabled_replication && var.replication_role_arn == null ? true : false
  replication_role_arn     = var.replication_role_arn != null ? var.replication_role_arn : try(aws_iam_role.replica[0].arn, "")
}

resource "aws_s3_bucket_replication_configuration" "this" {
  count  = local.enabled_replication ? 1 : 0
  bucket = aws_s3_bucket.this[0].bucket
  role   = local.replication_role_arn #  aws_iam_role.east_replication.arn

  dynamic "rule" {
    for_each = var.replication_rules == null ? [] : var.replication_rules

    content {
      id       = try(rule.value.id, null)
      priority = try(rule.value.priority, null)
      status   = try(tobool(rule.value.status) ? "Enabled" : "Disabled", "Disabled")

      delete_marker_replication {
        status = try(tobool(rule.value.delete_marker_replication) ? "Enabled" : "Disabled", "Disabled")
      }

      # see - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-what-is-isnot-replicated.html
      dynamic "existing_object_replication" {
        for_each = try(rule.value.existing_object_replication, null) == null ? [] : [true]

        content {
          status = try(tobool(rule.value.existing_object_replication) ? "Enabled" : "Disabled", "Disabled")
        }
      }

      # see - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-add-config.html#replication-config-optional-filter
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
        }
      }

      # see - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-add-config.html#replication-config-optional-dest-config
      dynamic "destination" {
        for_each = try(flatten([rule.value.destination]), [])

        content {
          bucket        = destination.value.bucket
          storage_class = try(destination.value.storage_class, null)
          account       = try(destination.value.account_id, destination.value.account, null)

          dynamic "access_control_translation" {
            for_each = try(flatten([destination.value.access_control_translation]), [])

            content {
              owner = access_control_translation.value.owner
            }
          }

          dynamic "encryption_configuration" {
            for_each = flatten([
              try(destination.value.encryption_configuration.replica_kms_key_id, destination.value.replica_kms_key_id, [])
            ])
            content {
              replica_kms_key_id = encryption_configuration.value
            }
          }

          dynamic "replication_time" {
            for_each = try(flatten([destination.value.replication_time]), [])
            content {
              status = try(tobool(replication_time.value.status) ? "Enabled" : replication_time.value.status, "Disabled")
              dynamic "time" {
                for_each = try(replication_time.value.minutes, null) == null ? [] : [true]
                content {
                  minutes = replication_time.value.minutes
                }
              }
            }
          }

          dynamic "metrics" {
            for_each = try(flatten([destination.value.metrics]), [])
            content {
              status = try(tobool(metrics.value.status) ? "Enabled" : metrics.value.status, "Disabled")
              dynamic "event_threshold" {
                for_each = try(flatten([metrics.value.minutes]), [])
                content {
                  minutes = metrics.value.minutes
                }
              }
            }
          }
        }
      }

      dynamic "source_selection_criteria" {
        for_each = try(flatten([rule.value.source_selection_criteria]), [])

        content {
          dynamic "replica_modifications" {
            for_each = flatten([
              try(source_selection_criteria.value.replica_modifications.enabled, source_selection_criteria.value.replica_modifications.status, [])
            ])
            content {
              status = try(tobool(replica_modifications.value) ? "Enabled" : "Disabled", replica_modifications.value, "Disabled")
            }
          }

          dynamic "sse_kms_encrypted_objects" {
            for_each = flatten([
              try(source_selection_criteria.value.sse_kms_encrypted_objects.enabled, source_selection_criteria.value.sse_kms_encrypted_objects.status, [])
            ])
            content {
              status = try(tobool(sse_kms_encrypted_objects.value) ? "Enabled" : "Disabled", sse_kms_encrypted_objects.value, "Disabled")
            }
          }
        }
      }

    }
    # end-of-content

  }
  # end-of-rule

  depends_on = [aws_s3_bucket_versioning.this]
}
