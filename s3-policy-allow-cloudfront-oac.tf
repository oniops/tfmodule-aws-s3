locals {
  policy_allow_cloudfront_oac = var.create && local.add_cloudfront_oac_policy ? templatefile("${path.module}/templates/s3-policy-allow-cloudfront-oac.tpl", {
    bucket_arn                   = aws_s3_bucket.this[0].arn
    cloudfront_distributions_arn = var.cloudfront_distributions_arn
  }) : ""
}
