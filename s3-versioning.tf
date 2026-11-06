locals {
  versioning = var.versioning != null && length(var.versioning) > 0 ? var.versioning : var.enable_versioning ? {
    status     = "Enabled"
    mfa_delete = "Disabled"
  } : {}

  enabled_versioning = var.create && length(local.versioning) > 0 ? true : false

  bucket_versioning_status = var.bucket_versioning_status != "" ? var.bucket_versioning_status : try(aws_s3_bucket_versioning.this[0].versioning_configuration[0].status, var.enable_versioning ? "Enabled" : "")
  enable_versioning_status = lower(local.bucket_versioning_status) == "enabled"
}

resource "aws_s3_bucket_versioning" "this" {
  count  = local.enabled_versioning ? 1 : 0
  bucket = aws_s3_bucket.this[0].bucket
  versioning_configuration {
    status     = lookup(local.versioning, "status", null)
    mfa_delete = lookup(local.versioning, "mfa_delete", null)
  }
  expected_bucket_owner = lookup(local.versioning, "expected_bucket_owner", null)
}
