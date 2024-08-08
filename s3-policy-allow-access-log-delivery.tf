locals {
  policy_allow_access_log_delivery = var.create ? try(data.aws_iam_policy_document.access_log_delivery[0].json, "") : ""
}

# Grant access to S3 log delivery group for server access logging
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-ownership-migrating-acls-prerequisites.html#object-ownership-server-access-logs
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/enable-server-access-logging.html#grant-log-delivery-permissions-general
data "aws_iam_policy_document" "access_log_delivery" {
  count = var.create && var.attach_access_log_delivery_policy ? 1 : 0

  statement {
    sid = "AWSAccessLogDeliveryWrite"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[0].arn}/*"]

    dynamic "condition" {
      for_each = length(var.access_log_delivery_policy_source_buckets) != 0 ? [true] : []
      content {
        test     = "ForAnyValue:ArnLike"
        variable = "aws:SourceArn"
        values   = var.access_log_delivery_policy_source_buckets
      }
    }

    dynamic "condition" {
      for_each = length(var.access_log_delivery_policy_source_accounts) != 0 ? [true] : []
      content {
        test     = "ForAnyValue:StringEquals"
        variable = "aws:SourceAccount"
        values   = var.access_log_delivery_policy_source_accounts
      }
    }
  }

  statement {
    sid    = "AWSAccessLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this[0].arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [local.account_id]
    }
  }
}
