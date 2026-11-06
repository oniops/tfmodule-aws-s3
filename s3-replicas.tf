locals {
  # Replication requires bucket versioning (see s3-versioning.tf).
  enabled_replication     = var.create && var.enable_replication && local.enable_versioning_status && length(var.replication_rules) > 0
  create_replication_role = local.enabled_replication && var.replication_role_arn == null
  replication_role_arn    = var.replication_role_arn != null ? var.replication_role_arn : try(aws_iam_role.replica[0].arn, "")
}

resource "aws_s3_bucket_replication_configuration" "this" {
  count  = local.enabled_replication ? 1 : 0
  bucket = aws_s3_bucket.this[0].bucket
  role   = local.replication_role_arn

  dynamic "rule" {
    for_each = var.replication_rules
    content {
      id       = rule.key
      priority = rule.value.priority
      status   = rule.value.enabled ? "Enabled" : "Disabled"

      delete_marker_replication {
        status = rule.value.delete_marker_replication ? "Enabled" : "Disabled"
      }

      # see - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-what-is-isnot-replicated.html
      dynamic "existing_object_replication" {
        for_each = rule.value.existing_object_replication ? ["Enabled"] : []
        content {
          status = existing_object_replication.value
        }
      }

      # see - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-add-config.html#replication-config-optional-filter
      # Always render a filter block; an empty filter replicates every object.
      filter {
        prefix = rule.value.filter.prefix

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
            prefix = and.value.prefix
            tags   = and.value.tags
          }
        }
      }

      # see - https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication-add-config.html#replication-config-optional-dest-config
      destination {
        bucket        = rule.value.destination.bucket
        storage_class = rule.value.destination.storage_class
        account       = rule.value.destination.account_id

        dynamic "access_control_translation" {
          for_each = rule.value.destination.owner_override ? ["Destination"] : []
          content {
            owner = access_control_translation.value
          }
        }

        dynamic "encryption_configuration" {
          for_each = rule.value.destination.replica_kms_key_id[*]
          content {
            replica_kms_key_id = encryption_configuration.value
          }
        }

        # S3 Replication Time Control supports 15 minutes only.
        dynamic "replication_time" {
          for_each = rule.value.destination.replication_time ? [15] : []
          content {
            status = "Enabled"
            time {
              minutes = replication_time.value
            }
          }
        }

        dynamic "metrics" {
          for_each = rule.value.destination.metrics ? [15] : []
          content {
            status = "Enabled"
            event_threshold {
              minutes = metrics.value
            }
          }
        }
      }

      dynamic "source_selection_criteria" {
        for_each = anytrue(values(rule.value.source_selection_criteria)) ? [rule.value.source_selection_criteria] : []
        content {
          dynamic "replica_modifications" {
            for_each = source_selection_criteria.value.replica_modifications ? ["Enabled"] : []
            content {
              status = replica_modifications.value
            }
          }

          dynamic "sse_kms_encrypted_objects" {
            for_each = source_selection_criteria.value.sse_kms_encrypted_objects ? ["Enabled"] : []
            content {
              status = sse_kms_encrypted_objects.value
            }
          }
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}
