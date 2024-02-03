locals {
  bucket_name = "lifecycle"

  context = {
    project          = "demo"
    region           = "ap-northeast-2"
    environment      = "PoC"
    team             = "DevOps"
    name_prefix      = "demo-an2p"
    s3_bucket_prefix = "demo-poc"
    domain           = "demo.io"
    pri_domain       = "demo.local"
    tags             = {
      Project = "demo"
    }
  }
}

module "s3Demo" {
  source = "../../"

  context                 = local.context
  bucket_name             = local.bucket_name
  object_ownership        = "ObjectWriter"
  sse_algorithm           = "aws:kms"
  kms_master_key_id       = data.aws_kms_key.origin.arn
  bucket_key_enabled      = true
  enable_bucket_lifecycle = true
  lifecycle_rules         = [
    {
      id     = "days-7-rule"
      status = "Enabled"
      filter = {
        prefix = "reports/"
      }
      expiration_days = 7
    },
    {
      id              = "days-30-rule"
      status          = "Enabled"
      expiration_days = 30
      filter          = {
        and = [
          {
            prefix = "logs/"
            tags   = {
              Porject     = "simple"
              ProductType = "EC2"
            }
          }
        ]
      }
    }
  ]

  force_destroy = true
}
