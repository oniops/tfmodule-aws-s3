module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.4"
  context = {
    project     = "demo"
    region      = "ap-northeast-2"
    environment = "PoC"
    customer    = "My Customer"
    department  = "DevOps"
    team        = "DevOps"
    owner       = "me@devopsdemo.io"
    domain      = "devopsdemo.io"
    pri_domain  = "devopsdemo.internal"
  }
}

data "aws_iam_policy_document" "trail" {
  statement {
    sid = "AWSCloudTrailAclCheck"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = [module.trail.bucket_arn,]
    actions   = ["s3:GetBucketAcl",]
  }

  statement {
    sid = "AWSCloudTrailWrite"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    resources = ["${module.trail.bucket_arn}/*"]
    actions   = ["s3:PutObject"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "Deny unencrypted object uploads"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["${module.trail.bucket_arn}/*",]
    actions   = ["s3:PutObject",]
    condition {
      test     = "StringNotEquals"
      values   = ["s3:x-amz-server-side-encryption"]
      variable = "aws:kms"
    }
  }

}


module "trail" {
  source              = "../../"
  context             = module.ctx.context
  bucket              = "central-cloudtrail"
  object_ownership    = "BucketOwnerPreferred"
  attach_custom_policy = ""
  object_lock_enabled = true
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = module.trail.bucket_id
  policy = data.aws_iam_policy_document.trail.json
}

# resource "aws_s3_bucket_versioning" "this" {
#   bucket = module.trail.bucket_id
#   versioning_configuration {
#     status     = "Enabled"
#     # mfa_delete = "Enabled" # Only available for ROOT account. just use CLI
#   }
#   expected_bucket_owner = local.account
# }
