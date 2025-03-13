locals {
  policy_deny_incorrect_encryption = var.create ? templatefile("${path.module}/templates/s3-policy-deny-incorrect-encryption.tpl", {
      bucket_arn = aws_s3_bucket.this[0].arn
      region     = local.region
    }) : ""
}
