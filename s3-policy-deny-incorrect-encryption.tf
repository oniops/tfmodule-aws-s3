locals {

  policy_deny_incorrect_encryption = var.create ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "denyIncorrectEncryptionHeaders"
        Effect    = "Deny"
        Principal = "*"
        Resource  = "${aws_s3_bucket.this[0].arn}/*"
        Action = ["s3:PutObject"]
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = [
              "AES256",
              "aws:kms",
            ]
          }
        }
      },
    ]
  }) : ""

}
