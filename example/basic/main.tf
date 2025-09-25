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

module "basic" {
  source                  = "../../"
  context                 = module.ctx.context
  bucket                  = "exam-basic"
  object_ownership        = "ObjectWriter"
  enable_bucket_lifecycle = true
  lifecycle_rules = [
    {
      id                = "default-rule"
      status            = "Enabled"
      glacier_days      = 180
      deep_archive_days = 365
      expiration_days   = 730
    }
  ]
  attach_deny_insecure_transport_policy = true
}
