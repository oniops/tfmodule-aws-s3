[
    {
        "Sid": "AllowELBLogWrite",
        "Effect": "Allow",
        "Principal": {
            "Service": "logdelivery.elasticloadbalancing.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${bucket_name}/*"
    }%{ if attach_elb_log_delivery_policy && (elb_service_account != null) },
    {
        "Sid": "AllowELBLogWriteRegion${region}",
        "Effect": "Allow",
        "Principal": {
            "AWS": "arn:aws:iam::${elb_service_account}:root"
        },
        "Action": "s3:PutObject",
        "Resource": "arn:aws:s3:::${bucket_name}/*"
    }
    %{ endif }
]
