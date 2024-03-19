data "aws_iam_policy_document" "denyInsecureTransport" {
  count = var.create_bucket && var.attach_deny_insecure_transport_policy ? 1 : 0
  statement {
    sid    = "denyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this[0].arn, "${aws_s3_bucket.this[0].arn}/*",]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

#locals {
#  policy_deny_insecure_transport = {
#    Sid       = "DenyInsecureTransport"
#    Effect    = "Deny"
#    Principal = "*"
#    Action    = "s3:*"
#    Resource  = [aws_s3_bucket.this[0].arn, "${aws_s3_bucket.this[0].arn}/*",]
#    Condition = {
#      Bool = {
#        "aws:SecureTransport" : "false"
#      }
#    }
#  }
#}
