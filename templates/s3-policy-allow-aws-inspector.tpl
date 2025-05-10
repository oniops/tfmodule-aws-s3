[
    {
        "Sid" : "AllowExportAWSInspectorReport",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "inspector2.amazonaws.com"
        },
        "Action" : [
          "s3:PutObjectAcl",
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ],
        "Resource" : [
            "${bucket_arn}/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:SourceAccount" : "${account_id}"
          },
          "ArnLike" : {
            "aws:SourceArn" : "arn:aws:inspector2:${region}:${account_id}:report/*"
          }
        }
    }
]