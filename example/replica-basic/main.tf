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

module "target" {
  source = "../../"
  providers = {
    aws = aws.replica
  }
  context           = module.ctx.context
  bucket_name       = "exr101-basic-replica-target"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

# 모든 객체를 복제 합니다.
module "source" {
  source             = "../../"
  context            = module.ctx.context
  bucket_name        = "exr101-basic-replica-source"
  object_ownership   = "ObjectWriter"
  bucket_key_enabled = false
  enable_versioning  = true
  enable_replication = true
  replication_rules = [
    {
      id                        = "basic-replica-rule"
      status                    = true
      delete_marker_replication = false
      destination = {
        bucket        = module.target.bucket_arn
      }
    }
  ]
  force_destroy = true
  depends_on    = [module.target]
}
