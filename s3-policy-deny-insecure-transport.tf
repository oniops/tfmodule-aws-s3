locals {
  policy_deny_insecure_transport = var.create ? templatefile("${path.module}/templates/s3-policy-deny-insecure-transport.tpl", {
      bucket_arn = aws_s3_bucket.this[0].arn
    }) : ""
}