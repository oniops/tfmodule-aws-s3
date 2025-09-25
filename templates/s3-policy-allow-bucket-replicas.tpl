{
  "Version": "2012-10-17",
  "Statement": [
%{ if length(s3_destination_kms_arns) > 0 ~}
    {
      "Sid": "EncryptTargetObjectsForReplication",
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": ${jsonencode(s3_destination_kms_arns)}
    },%{ endif ~}
%{ if replication_report_bucket_arn != null ~}
    {
      "Sid": "AllowPutReportBucket",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": [
        "${replication_report_bucket_arn}",
        "${replication_report_bucket_arn}/*"
      ]
    },%{ endif ~}
    {
      "Sid": "AllowPrimaryToInitiateReplication",
      "Effect": "Allow",
      "Action": "s3:InitiateReplication",
      "Resource": [
        "${s3_origin_arn}",
        "${s3_origin_arn}/*"
      ]
    },
    {
      "Sid": "AllowPrimaryToGetReplication",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetReplicationConfiguration",
        "s3:PutInventoryConfiguration",
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging",
        "s3:GetObjectRetention",
        "s3:GetObjectLegalHold"
      ],
      "Resource": [
        "${s3_origin_arn}",
        "${s3_origin_arn}/*"
      ]
    },
    {
      "Sid": "AllowPrimaryToReplicate",
      "Effect": "Allow",
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:GetObjectVersionTagging",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ],
      "Resource": ${jsonencode(s3_destination_bucket_arns)},
      "Condition": {
        "StringLikeIfExists": {
          "s3:x-amz-server-side-encryption": [
            "aws:kms",
            "aws:kms:dsse",
            "AES256"
          ]
        }
      }
    }
%{ if kms_master_key_id != null ~},
    {
      "Sid": "DecryptSourceObjectsForReplication",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": ["${kms_master_key_id}"]
    }%{ endif ~}
  ]
}