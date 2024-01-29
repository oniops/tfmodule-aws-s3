locals {
  bucket_name = "simple"

  context = {
    project          = "sim"
    region           = "ap-northeast-2"
    environment      = "PoC"
    team             = "DevOps"
    name_prefix      = "sim-an2p"
    s3_bucket_prefix = "sim-poc"
    domain           = "sim.io"
    pri_domain       = "sim.local"
    tags             = {
      Project = "sim"
    }
  }
}


module "s3Rpt" {
  source            = "../../"
  context           = local.context
  bucket_name       = "replica-report"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

module "s3Dest" {
  source    = "../../"
  providers = {
    aws = aws.replica
  }
  context           = local.context
  bucket_name       = "${local.bucket_name}-dest"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}


module "s3Origin" {
  source = "../../"

  context                 = local.context
  bucket_name             = local.bucket_name
  object_ownership        = "ObjectWriter"
  sse_algorithm           = "aws:kms"
  kms_master_key_id       = data.aws_kms_key.origin.arn
  bucket_key_enabled      = true
  enable_versioning       = true
  enable_bucket_lifecycle = false
  lifecycle_rules         = [
    {
      id              = "expire-one-year-rule"
      status          = "Enabled"
      expiration_days = 365
    }
  ]
  enable_replication            = true
  replication_report_bucket_arn = module.s3Rpt.bucket_arn
  replication_rules             = [
    {
      id                        = "default-rule"
      status                    = true
      delete_marker_replication = false
      destination               = {
        bucket             = module.s3Dest.bucket_arn
        storage_class      = "STANDARD_IA"
        replica_kms_key_id = data.aws_kms_key.replica.arn
      }
      replication_time   = {
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

  force_destroy     = true

  depends_on = [
    module.s3Dest,
    module.s3Rpt
  ]

}
