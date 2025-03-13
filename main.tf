locals {
  project                   = var.context.project
  region                    = var.context.region
  account_id                = var.context.account_id
  tags                      = var.context.tags
  bucket_name               = var.bucket != null ? var.bucket : "${var.context.s3_bucket_prefix}-${var.bucket_name}-s3"
  bucket_simple_name        = var.bucket_name != null ? var.bucket_name : trimsuffix(trimprefix(var.bucket, "${var.context.s3_bucket_prefix}-"), "-s3")
  enabled_s3_bucket_logging = var.create && length(var.s3_logs_bucket) > 1 ? true : false
  enabled_object_lock       = var.create && var.object_lock_enabled ? true : false
}

data "aws_canonical_user_id" "current" {
  count = var.create ? 1 : 0
}

resource "aws_s3_bucket" "this" {
  count  = var.create ? 1 : 0
  bucket = local.bucket_name

  object_lock_enabled = var.object_lock_enabled

  tags = merge(local.tags, {
    Name = local.bucket_name
  })

  force_destroy = var.force_destroy

  lifecycle {
    ignore_changes = [
      # acceleration_status, - The attribute "acceleration_status" is deprecated. Refer to the provider documentation for details.
      # acl, -  The attribute "acl" is deprecated. Refer to the provider documentation for details.
      # request_payer, - The attribute "request_payer" is deprecated. Refer to the provider documentation for details.
      grant,
      cors_rule,
      lifecycle_rule,
      logging,
      object_lock_configuration,
      replication_configuration,
      server_side_encryption_configuration,
      versioning,
      website
    ]
  }

}


# Block public access settings
resource "aws_s3_bucket_public_access_block" "this" {
  count = var.create ? 1 : 0
  bucket = try(aws_s3_bucket.this[0].id, "")

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Bucket acl
resource "aws_s3_bucket_acl" "this" {
  count = !var.create || var.object_ownership == "BucketOwnerEnforced" ? 0 : 1

  bucket = try(aws_s3_bucket.this[0].id, "")
  # expected_bucket_owner = aws_account_id

  access_control_policy {

    # grant.permission = FULL_CONTROL WRITE WRITE_ACP READ READ_ACP

    grant {
      grantee {
        id   = data.aws_canonical_user_id.current[0].id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    #  grant {
    #    grantee {
    #      uri  = "http://acs.amazonaws.com/groups/global/AllUsers"
    #      type = "Group"
    #    }
    #    permission = "READ_ACP"
    #  }
    #
    #  grant {
    #    grantee {
    #      type = "Group"
    #      uri  = "http://acs.amazonaws.com/groups/global/AuthenticatedUsers"
    #    }
    #    permission = "WRITE_ACP"
    #  }
    #
    #  grant {
    #    grantee {
    #      type = "Group"
    #      uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
    #    }
    #    permission = "WRITE"
    #  }

    owner {
      id = data.aws_canonical_user_id.current[0].id
    }

  }

  depends_on = [
    aws_s3_bucket.this,
    aws_s3_bucket_ownership_controls.this
  ]
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count = var.create ? 1 : 0
  bucket = try(aws_s3_bucket.this[0].id, "")

  rule {
    object_ownership = var.object_ownership # ObjectWriter or BucketOwnerEnforced, BucketOwnerEnforced
  }
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = local.enabled_object_lock ? 1 : 0

  bucket = try(aws_s3_bucket.this[0].id, "")

  rule {
    default_retention {
      mode = var.object_lock_mode
      days = var.object_lock_days
    }
  }
}
