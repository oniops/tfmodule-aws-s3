# Grant access to S3 log delivery group for server access logging
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-ownership-migrating-acls-prerequisites.html#object-ownership-server-access-logs
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html#grant-log-delivery-permissions-general

locals {
  policy_allow_access_log_delivery = var.create ? templatefile("${path.module}/templates/s3-policy-allow-access-log-delivery.tpl", {
      bucket_arn                                 = aws_s3_bucket.this[0].arn
      account_id                                 = local.account_id # var.context.account_id
      access_log_delivery_policy_source_buckets  = var.access_log_delivery_policy_source_buckets
      access_log_delivery_policy_source_accounts = var.access_log_delivery_policy_source_accounts
    }) : ""
}