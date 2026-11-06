locals {
  replica_role_name   = "${local.project}${replace(title(local.bucket_simple_name), "-", "")}S3CrrRole"
  replica_policy_name = "${local.project}${replace(title(local.bucket_simple_name), "-", "")}S3CrrPolicy"
  s3_origion_arn      = try(aws_s3_bucket.this[0].arn, "")

  # Template inputs. values() of a map is ordered by key, so the rendered policy is stable.
  s3_destination_bucket_arns = distinct(flatten([
    for rule in values(var.replication_rules) : [rule.destination.bucket, "${rule.destination.bucket}/*"]
  ]))
  s3_destination_kms_arns = distinct(compact([
    for rule in values(var.replication_rules) : rule.destination.replica_kms_key_id
  ]))

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

  replica_policy = templatefile("${path.module}/templates/s3-policy-allow-bucket-replicas.tftpl", {
    s3_origin_arn                 = local.s3_origion_arn
    s3_destination_bucket_arns    = local.s3_destination_bucket_arns
    s3_destination_kms_arns       = local.s3_destination_kms_arns
    kms_master_key_id             = local.kms_master_key_id
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

# aws_iam_policy_attachment manages ALL attachments of the policy exclusively, and destroying it
# detaches the policy from the role. Forget the old resource without destroying it; the new
# role-scoped attachment below re-attaches the same policy (AttachRolePolicy is idempotent).
removed {
  from = aws_iam_policy_attachment.replica

  lifecycle {
    destroy = false
  }
}

resource "aws_iam_role_policy_attachment" "replica" {
  count      = local.create_replication_role ? 1 : 0
  role       = aws_iam_role.replica[0].name
  policy_arn = aws_iam_policy.replica[0].arn
}
