locals {
  tags = var.context.tags
}

data "aws_canonical_user_id" "current" {}

resource "aws_s3_bucket" "this" {
  bucket              = var.bucket
  # acl                 = "private"
  object_lock_enabled = false

  versioning {
    enabled    = false
    mfa_delete = false
  }

  tags = merge(local.tags, { Name = var.bucket })


  lifecycle {
    ignore_changes = [
      acceleration_status,
      acl,
      grant,
      cors_rule,
      lifecycle_rule,
      logging,
      object_lock_configuration,
      replication_configuration,
      request_payer,
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
      sse_algorithm = "AES256" # AES256 or aws:kms
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

# S3 access logs
resource "aws_s3_bucket_logging" "this" {
  count         = var.s3_logs_bucket != null ? 1 : 0
  bucket        = var.bucket
  target_bucket = var.s3_logs_bucket
  target_prefix = "logs/"
}
