[
    {
        "Sid": "AWSLogDeliveryWrite",
        "Effect": "Allow",
        "Principal": {
            "Service": "delivery.logs.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${bucket_name}/AWSLogs/*",
        "Condition": {
            "StringEquals": {
                "aws:SourceAccount": "${account_id}",
                "s3:x-amz-acl": "bucket-owner-full-control"
            },
            "ArnLike": {
                "aws:SourceArn": "arn:aws:logs:${region}:${account_id}:*"
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
        "Resource": "arn:aws:s3:::${bucket_name}",
        "Condition": {
            "StringEquals": {
                "aws:SourceAccount": "${account_id}"
            }
        }
    }
]
