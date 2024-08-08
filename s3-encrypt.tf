locals {
  kms_master_key_id  = var.kms_master_key_id != null ? var.kms_master_key_id : var.sse_algorithm == "aws:kms" ? "aws/s3" : null
  bucket_key_enabled = var.sse_algorithm == "aws:kms" ? var.bucket_key_enabled : null
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.create ? 1 : 0
  bucket = aws_s3_bucket.this[0].bucket

  expected_bucket_owner = var.expected_bucket_owner
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = local.kms_master_key_id
    }
    bucket_key_enabled = try(local.bucket_key_enabled, null)
  }

  depends_on = [aws_s3_bucket.this]
}
