locals {
  policy_allow_vpce = var.create && local.add_vpce_policy ? templatefile("${path.module}/templates/s3-policy-allow-vpce.tpl", {
    bucket_arn  = aws_s3_bucket.this[0].arn
    source_vpce = var.source_vpce
  }) : ""
}
