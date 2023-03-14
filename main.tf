locals {
  tags                      = var.context.tags
  enabled_s3_bucket_logging = length(var.s3_logs_bucket) > 1 ? true : false
  enabled_object_lock       = var.object_lock_enabled ? true : false
}

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket
  # acl                 = "private"

  object_lock_enabled = var.object_lock_enabled

  #  replace with "aws_s3_bucket_versioning"
  #  versioning {
  #    enabled    = false
  #    mfa_delete = false
  #  }

  tags = merge(local.tags, { Name = var.bucket })


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

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      # kms_master_key_id = aws_kms_key.mykey.arn # for CMK
      sse_algorithm = var.sse_algorithm
    }
  }

  depends_on = [aws_s3_bucket.this]
}

# Block public access settings
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Bucket acl
resource "aws_s3_bucket_acl" "this" {
  count = var.object_ownership == "BucketOwnerEnforced" ? 0 : 1

  bucket = aws_s3_bucket.this.id
  # expected_bucket_owner = aws_account_id

  access_control_policy {

    # grant.permission = FULL_CONTROL WRITE WRITE_ACP READ READ_ACP

    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
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
      id = data.aws_canonical_user_id.current.id
    }

  }

  depends_on = [aws_s3_bucket.this]
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership # ObjectWriter or BucketOwnerEnforced, BucketOwnerEnforced
  }
}

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = local.enabled_object_lock ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode = var.object_lock_mode
      days = var.object_lock_days
    }
  }
}
