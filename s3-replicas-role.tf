locals {
  replica_role_name   = "${var.context.project}${replace(title(local.bucket_simple_name), "-", "")}S3CrrRole"
  replica_policy_name = "${var.context.project}${replace(title(local.bucket_simple_name), "-", "")}S3CrrPolicy"
  s3_origion_arn = try(aws_s3_bucket.this[0].arn, "")
  s3_destination_bucket_arns = try(distinct(flatten([
    for rule in var.replication_rules :[rule.destination.bucket, "${rule.destination.bucket}/*"]
  ])), ["arn:aws:s3:::you-must-define-destination-s3-bucket-arn"])

  s3_destination_kms_arns = var.replication_rules == null ? null : distinct([
    for rule in var.replication_rules :rule.destination.replica_kms_key_id
  ])

  replica_trust = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Sid    = "AllowPrimaryToAssumeServiceRole",
          Effect = "Allow",
          Principal = {
            Service = [
              "s3.amazonaws.com",
              "batchoperations.s3.amazonaws.com"
            ]
          },
          Action   = "sts:AssumeRole",
          Resource = "s3-bucket-arn/*"
        }
      ]
    }
  )

  replica_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = flatten(concat([
          local.s3_destination_kms_arns != null ? [
          {
            Sid    = "EncryptTargetObjectsForReplication",
            Effect = "Allow",
            Action = [
              "kms:Encrypt",
              "kms:GenerateDataKey"
            ],
            Resource = local.s3_destination_kms_arns
          }
        ] : [],
          var.replication_report_bucket_arn != null ? [
          {
            Sid    = "AllowPutReportBucket",
            Effect = "Allow",
            Action = "s3:PutObject"
            Resource = [
              var.replication_report_bucket_arn,
              "${var.replication_report_bucket_arn}/*"
            ]
          }
        ] : [],
        {
          # https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-policies.html
          Sid    = "AllowPrimaryToInitiateReplication",
          Effect = "Allow",
          Action = "s3:InitiateReplication",
          Resource = [
            # local.s3_origion_arn,
            # "${local.s3_origion_arn}/*"
          ]
        },
        {
          Sid    = "AllowPrimaryToGetReplication",
          Effect = "Allow",
          Action = [
            "s3:ListBucket",
            "s3:GetReplicationConfiguration",
            "s3:PutInventoryConfiguration",
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging",
            "s3:GetObjectRetention",
            "s3:GetObjectLegalHold"
          ],
          Resource = [
            # local.s3_origion_arn,
            # "${local.s3_origion_arn}/*",
          ]
        },
        {
          Sid    = "AllowPrimaryToReplicate",
          Effect = "Allow",
          Action = [
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags",
            "s3:GetObjectVersionTagging",
            "s3:ObjectOwnerOverrideToBucketOwner"
          ],
          Resource = local.s3_destination_bucket_arns,
          Condition = {
            StringLikeIfExists = {
              "s3:x-amz-server-side-encryption" = [
                "aws:kms",
                "aws:kms:dsse",
                "AES256"
              ]
            }
          }
        },
        {
          Sid    = "DecryptSourceObjectsForReplication",
          Effect = "Allow",
          Action = [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          Resource = local.kms_master_key_id
        }
      ]))
    }
  )
}

resource "aws_iam_role" "replica" {
  count              = local.create_replication_role ? 1 : 0
  name               = local.replica_role_name
  assume_role_policy = local.replica_trust
  tags = {
    Name = local.replica_role_name
  }
}


resource "aws_iam_policy" "replica" {
  count  = local.create_replication_role ? 1 : 0
  name   = local.replica_policy_name
  policy = local.replica_policy
  tags = merge(local.tags, {
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
