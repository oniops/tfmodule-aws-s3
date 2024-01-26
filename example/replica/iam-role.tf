locals {
  bucket_prefix = local.context.bucket_prefix
  role_name   = format("%s-%s-role", local.bucket_prefix, "origin")
  policy_name = format("%s-%s-policy", local.bucket_prefix, "origin")
}

resource "aws_iam_role" "replica" {
  name               = local.role_name
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
POLICY
}


data "aws_iam_policy_document" "replica" {
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-policies.html
  statement {
    sid     = "AllowPrimaryToInitiateReplication"
    effect  = "Allow"
    actions = [
      "s3:InitiateReplication"
    ]
    resources = [module.origin.bucket_arn]
  }

  statement {
    sid     = "AllowPrimaryToBatchReplication"
    effect  = "Allow"
    actions = [
      "s3:PutInventoryConfiguration",
      "s3:GetReplicationConfiguration"
    ]
    resources = [module.origin.bucket_arn]
  }

  statement {
    sid     = "AllowPrimaryToGetReplicationConfiguration"
    effect  = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [module.origin.bucket_arn]
  }

  statement {
    sid     = "AllowPrimaryToGetObjectVersion"
    effect  = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
      format("%s/*", module.origin.bucket_arn)
    ]
  }

  statement {
    sid     = "AllowPrimaryToReplicate"
    effect  = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = [
      format("%s/*", module.replica.bucket_arn)
    ]
  }

  statement {
    sid     = "DecryptSourceObjectsForReplication"
    effect  = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      data.aws_kms_key.origin.arn
    ]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${local.context.region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [
        format("%s/*", module.origin.bucket_arn)
      ]
    }

  }

  statement {
    sid     = "EncryptTargetObjectsForReplication"
    effect  = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      data.aws_kms_key.replica.arn
    ]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${local.replica_region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [
        format("%s/*", module.replica.bucket_arn)
      ]
    }
  }
}

resource "aws_iam_policy" "replica" {
  name   = local.policy_name
  policy = data.aws_iam_policy_document.replica.json
}

resource "aws_iam_policy_attachment" "replica" {
  name       = format("%s-%s-policy", local.bucket_prefix, "replica")
  roles      = [aws_iam_role.replica.name]
  policy_arn = aws_iam_policy.replica.arn
}