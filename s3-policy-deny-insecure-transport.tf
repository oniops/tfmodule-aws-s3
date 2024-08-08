locals {

  policy_deny_insecure_transport = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          "Sid" : "denyInsecureTransport",
          "Effect" : "Deny",
          "Principal" : "*",
          "Action" : "s3:*",
          "Resource" : [
            aws_s3_bucket.this[0].arn,
            "${aws_s3_bucket.this[0].arn}/*"
          ],
          "Condition" : {
            "Bool" : {
              "aws:SecureTransport" : "false"
            }
          }
        }
      ]
    }
  )

}