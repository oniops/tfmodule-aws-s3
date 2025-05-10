locals {
  policy_allow_aws_inspector = var.create && var.attach_aws_inspector_report_policy ? templatefile("${path.module}/templates/s3-policy-allow-aws-inspector.tpl", {
      bucket_arn                                 = aws_s3_bucket.this[0].arn
      account_id                                 = local.account_id
      region  = local.region
    }) : ""
}