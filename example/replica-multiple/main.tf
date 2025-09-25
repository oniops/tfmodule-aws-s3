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

module "targetFirst" {
  source    = "../../"
  providers = {
    aws = aws.replica
  }
  context           = module.ctx.context
  bucket_name       = "exr301-multiple-replica-first-target"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

module "targetSecond" {
  source    = "../../"
  providers = {
    aws = aws.replica
  }
  context           = module.ctx.context
  bucket_name       = "exr301-multiple-replica-second-target"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

# `/first`는 exr301-multiple-replica-first-target 버킷으로 복제하고 `second/`는 exr301-multiple-replica-second-target 버킷으로 복제 합니다.
module "source" {
  source = "../../"

  context                 = module.ctx.context
  bucket_name             = "exr301-multiple-replica-source"
  object_ownership        = "ObjectWriter"
  sse_algorithm           = "aws:kms"
  kms_master_key_id       = data.aws_kms_alias.origin.target_key_arn
  bucket_key_enabled      = true
  enable_versioning       = true
  enable_replication = true
  replication_rules  = [
    {
      id     = "first-rule"
      status = true

      filter = {
        prefix = "first/"
      }

      destination = {
        bucket             = module.targetFirst.bucket_arn
      }
    },
    {
      id       = "second-rule"
      status   = true
      priority = 10
      
      filter   = {
        prefix = "second/"
      }
      
      source_selection_criteria = {
        sse_kms_encrypted_objects = {
          enabled = true
        }
      }
      
      destination = {
        bucket             = module.targetSecond.bucket_arn
        replica_kms_key_id = data.aws_kms_alias.replica.target_key_arn
      }
    }
  ]

  force_destroy = true

  depends_on = [
    module.targetFirst,
    module.targetSecond
  ]

}
