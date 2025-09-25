locals {
  replica_role_name          = "${local.project}${replace(title(local.bucket_simple_name), "-", "")}S3CrrRole"
  replica_policy_name        = "${local.project}${replace(title(local.bucket_simple_name), "-", "")}S3CrrPolicy"
  s3_origion_arn             = try(aws_s3_bucket.this[0].arn, "")
  s3_destination_bucket_arns = (try(distinct(flatten([for rule in var.replication_rules : [rule.destination.bucket, "${rule.destination.bucket}/*"]])), ["arn:aws:s3:::you-must-define-destination-s3-bucket-arn"]))
  s3_destination_kms_arns    = (var.replication_rules == null ? [] : distinct(compact([for rule in var.replication_rules : try(rule.destination.replica_kms_key_id, null)])))

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
          Action = "sts:AssumeRole"
        }
      ]
    }
  )

  replica_policy = templatefile("${path.module}/templates/s3-policy-allow-bucket-replicas.tpl", {
    s3_origin_arn                = local.s3_origion_arn
    s3_destination_bucket_arns   = local.s3_destination_bucket_arns
    s3_destination_kms_arns      = local.s3_destination_kms_arns
    kms_master_key_id            = local.kms_master_key_id
    replication_report_bucket_arn = var.replication_report_bucket_arn
  })
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
