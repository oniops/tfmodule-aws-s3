module "ctx" {
  source  = "git::https://code.bespinglobal.com/scm/op/tfmodule-context.git"
  context = {
    aws_profile = ""
    project     = "otcmp"
    region      = "ap-northeast-1"
    environment = "Testbed"
    department  = "OpsNow"
    owner       = "yoonsoo.chang@bespinglobal.com"
    customer    = "OpsNow Test Company"
    domain      = "opsnowtest.co.uk"
    pri_domain  = "backend.opsnow.com"
    cost_center = 1001
    team        = "OpsNow"
  }
}

locals {
  project       = module.ctx.project
  name_prefix   = module.ctx.name_prefix
  bucket_prefix = "${local.project}-tbd"
  tags          = module.ctx.tags
  account       = "370166107047"
}

module "trail" {
  source              = "../../"
  context             = module.ctx.context
  bucket              = format("%s-%s-s3", local.bucket_prefix, "cloudtrail")
  object_ownership    = "BucketOwnerPreferred"
  object_lock_enabled = true
  sse_algorithm       = "aws:kms"
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

resource "aws_s3_bucket_policy" "policy" {
  bucket = module.trail.bucket_id
  policy = data.aws_iam_policy_document.trail.json
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = module.trail.bucket_id
  versioning_configuration {
    status     = "Enabled"
    # mfa_delete = "Enabled" # Only available for ROOT account
  }
  expected_bucket_owner = local.account
  #
  # mfa = "${var.mfa_serial} ${var.mfa_token}"
}
