locals {
  policy_allow_lb_log_delivery = var.create ? jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AWSLogDeliveryWrite",
        "Effect": "Allow",
        "Principal": {
          "Service": "delivery.logs.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${local.bucket_name}/AWSLogs/*",
        "Condition": {
          "StringEquals": {
            "aws:SourceAccount": local.account_id,
            "s3:x-amz-acl": "bucket-owner-full-control"
          },
          "ArnLike": {
            "aws:SourceArn": "arn:aws:logs:${local.region}:${local.account_id}:*"
          }
        }
      },
      {
        "Sid": "AWSLogDeliveryAclCheck",
        "Effect": "Allow",
        "Principal": {
          "Service": "delivery.logs.amazonaws.com"
        },
        "Action": [
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ],
        "Resource": [
          "arn:aws:s3:::${local.bucket_name}"
        ],
        "Condition": {
          "StringEquals": {
            "aws:SourceAccount": local.account_id
          }
        }
      }
    ]
  }) : ""
}
