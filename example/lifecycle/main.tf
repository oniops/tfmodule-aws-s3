module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.4"
  context = {
    project     = "demo"
    region      = "ap-northeast-2"
    environment = "PoC"
    customer    = "My Customer"
    department  = "DevOps"
    team        = "DevOps"
    owner       = "me@devopsdemo.io"
    domain      = "devopsdemo.io"
    pri_domain  = "devopsdemo.internal"
  }
}

module "s3Demo" {
  source                  = "../../"
  context                 = module.ctx.context
  bucket_name             = "ex01-hello-lifecycle"
  object_ownership        = "ObjectWriter"
  sse_algorithm           = "aws:kms"
  kms_master_key_id       = data.aws_kms_alias.origin.target_key_arn
  bucket_key_enabled      = true
  enable_bucket_lifecycle = true
  lifecycle_rules = [
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
      filter = {
        and = [
          {
            prefix = "logs/"
            tags = {
              Porject     = "demo"
              ProductType = "EC2"
            }
          }
        ]
      }
    }
  ]

  force_destroy = true
}
