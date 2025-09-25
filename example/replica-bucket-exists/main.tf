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
  bucket_name       = "ex03-replica-target"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

module "source" {
  source            = "../../"
  context           = module.ctx.context
  bucket_name       = "ex03-replica-source"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

module "report" {
  source           = "../../"
  context          = module.ctx.context
  bucket_name      = "ex03-replica-report"
  object_ownership = "ObjectWriter"
  force_destroy    = true
}

module "replica" {
  source                  = "../../"
  context                 = module.ctx.context
  bucket_name             = module.source.bucket_name
  object_ownership        = "ObjectWriter"
  sse_algorithm           = "aws:kms"
  kms_master_key_id       = data.aws_kms_alias.origin.target_key_arn
  bucket_key_enabled      = true
  enable_versioning       = true
  enable_bucket_lifecycle = false
  lifecycle_rules = [
    {
      id              = "expire-one-year-rule"
      status          = "Enabled"
      expiration_days = 365
    }
  ]
  enable_replication            = true
  replication_report_bucket_arn = module.report.bucket_arn
  replication_rules = [
    {
      id                        = "default-rule"
      status                    = true
      delete_marker_replication = false
      destination = {
        bucket             = module.target.bucket_arn
        storage_class      = "STANDARD" # "STANDARD_IA"
        replica_kms_key_id = data.aws_kms_alias.replica.target_key_arn
      }
      replication_time = {
        status  = true
        minutes = 15
      }
      metrics = {
        status  = true
        minutes = 15
      }
      source_selection_criteria = {
        sse_kms_encrypted_objects = {
          enabled = true
        }
      }
    }
  ]

  force_destroy = true

  depends_on = [
    module.source,
    module.target,
    module.report
  ]

}
