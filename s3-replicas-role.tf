locals {
  replica_role_name          = format("%s%sS3CrrRole", var.context.project, replace(title(local.bucket_simple_name), "-", ""))
  replica_policy_name        = format("%s%sS3CrrPolicy", var.context.project, replace(title(local.bucket_simple_name), "-", ""))
  s3_origion_arn             = try(aws_s3_bucket.this[0].arn, "")
  s3_destination_bucket_arns = try(distinct(flatten([
    for rule in var.replication_rules :[rule.destination.bucket, "${rule.destination.bucket}/*"]
  ])), ["arn:aws:s3:::you-must-define-destination-s3-bucket-arn"])

  s3_destination_kms_arns = var.replication_rules == null ? [] : distinct([
    for rule in var.replication_rules :rule.destination.replica_kms_key_id
  ])
}

data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "AllowPrimaryToAssumeServiceRole"
    effect  = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = [
        "s3.amazonaws.com",
        "batchoperations.s3.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "replica" {
  count              = local.create_replication_role ? 1 : 0
  name               = local.replica_role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = {
    Name = local.replica_role_name
  }
}

data "aws_iam_policy_document" "replica" {
  count = local.create_replication_role ? 1 : 0
  statement {
    sid     = "AllowPrimaryToGetReplication"
    effect  = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
      "s3:PutInventoryConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]
    resources = [
      local.s3_origion_arn,
      format("%s/*", local.s3_origion_arn)
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

    resources = local.s3_destination_bucket_arns

    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms", "aws:kms:dsse", "AES256"]
    }
  }

  statement {
    sid     = "DecryptSourceObjectsForReplication"
    effect  = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      local.kms_master_key_id
    ]
  }

  dynamic "statement" {
    for_each = local.s3_destination_kms_arns
    content {
      sid     = "EncryptTargetObjectsForReplication"
      effect  = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = local.s3_destination_kms_arns
    }
  }

  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-policies.html
  statement {
    sid     = "AllowPrimaryToInitiateReplication"
    effect  = "Allow"
    actions = [
      "s3:InitiateReplication"
    ]
    resources = [
      local.s3_origion_arn,
      format("%s/*", local.s3_origion_arn)
    ]
  }

  dynamic "statement" {
    for_each = var.replication_report_bucket_arn == null? [] : [true]
    content {
      sid     = "AllowPutReportBucket"
      effect  = "Allow"
      actions = [
        "s3:PutObject"
      ]
      resources = [
        var.replication_report_bucket_arn,
        format("%s/*", var.replication_report_bucket_arn)
      ]
    }
  }

}

resource "aws_iam_policy" "replica" {
  count  = local.create_replication_role ? 1 : 0
  name   = local.replica_policy_name
  policy = data.aws_iam_policy_document.replica[0].json
  tags   = merge(local.tags, {
    Name = local.replica_policy_name
  })
}

resource "aws_iam_policy_attachment" "replica" {
  count = local.create_replication_role ? 1 : 0
  name  = local.replica_policy_name
  roles = [
    aws_iam_role.replica[0].name
  ]
  policy_arn = aws_iam_policy.replica[0].arn
}
