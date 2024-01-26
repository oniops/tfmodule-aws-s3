locals {
  enabled_versioning = var.create_bucket && var.versioning != null && length(var.versioning) > 0 ? true : false
}

resource "aws_s3_bucket_versioning" "this" {
  count  = local.enabled_versioning ? 1 : 0
  bucket = aws_s3_bucket.this[0].bucket
  expected_bucket_owner = lookup(var.versioning, "expected_bucket_owner", null)
  versioning_configuration {
    status     = lookup(var.versioning, "status", null)
    mfa_delete = lookup(var.versioning, "mfa_delete", null)
  }
}
