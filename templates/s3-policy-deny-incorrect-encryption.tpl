[
    {
        "Sid" : "denyIncorrectEncryptionHeaders",
        "Effect" : "Deny",
        "Principal": "*",
        "Action": "s3:PutObject",
        "Resource": "${bucket_arn}/*",
        "Condition": {
            "StringNotEquals": {
                "s3:x-amz-server-side-encryption": [
                    "AES256",
                    "aws:kms"
                ]
            }
        }
    }
]