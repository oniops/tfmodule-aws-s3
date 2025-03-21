[
    {
        "Sid": "AWSAccessLogDeliveryWrite",
        "Effect": "Allow",
        "Principal": {
            "Service": "logging.s3.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "${bucket_arn}/*",
        "Condition": {
            %{ if length(access_log_delivery_policy_source_buckets) != 0 }
            "ArnLike": {
                "aws:SourceArn": ${jsonencode(access_log_delivery_policy_source_buckets)}
            }%{ if length(access_log_delivery_policy_source_accounts) > 0 },%{ endif }
            %{ endif }
            %{ if length(access_log_delivery_policy_source_accounts) != 0 }
            "StringEquals": {
                "aws:SourceAccount": ${jsonencode(access_log_delivery_policy_source_accounts)}
            }
            %{ endif }
        }
    },
    {
        "Sid": "AWSAccessLogDeliveryAclCheck",
        "Effect": "Allow",
        "Principal": {
            "Service": "logging.s3.amazonaws.com"
        },
        "Action": "s3:GetBucketAcl",
        "Resource": "${bucket_arn}",
        "Condition": {
           "StringEquals": {
               "aws:SourceAccount": "${account_id}"
           }
       }
    }
]