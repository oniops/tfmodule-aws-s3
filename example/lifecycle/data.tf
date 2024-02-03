data "aws_caller_identity" "current" {}

data "aws_kms_key" "origin" {
  key_id = "alias/aws/s3"
}

data "aws_kms_key" "replica" {
  provider = aws.replica
  key_id = "alias/aws/s3"
}
