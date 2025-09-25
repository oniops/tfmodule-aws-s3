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
  bucket_name       = "ex02-hello-replica-target"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

module "source" {
  source             = "../../"
  context            = module.ctx.context
  bucket_name        = "ex02-hello-replica-soruce"
  object_ownership   = "ObjectWriter"
  sse_algorithm      = "aws:kms"
  kms_master_key_id  = data.aws_kms_alias.origin.target_key_arn
  bucket_key_enabled = true
  enable_versioning  = true
  enable_replication = true
  replication_rules = [
    {
      id                        = "default-replica-rule"
      status                    = true
      delete_marker_replication = false
      destination = {
        bucket             = module.target.bucket_arn
        storage_class      = "STANDARD" # "STANDARD_IA"
        replica_kms_key_id = data.aws_kms_alias.replica.target_key_arn
      }

      source_selection_criteria = {
        sse_kms_encrypted_objects = {
          enabled = true
        }
      }

    }
  ]
  force_destroy = true
  depends_on    = [module.target]
}
