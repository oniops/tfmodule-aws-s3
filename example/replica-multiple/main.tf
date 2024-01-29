locals {
  project     = "demo"
  bucket_name = "world"

  context = {
    project          = local.project
    region           = "ap-northeast-2"
    environment      = "PoC"
    team             = "DevOps"
    name_prefix      = "${local.project}-an2p"
    s3_bucket_prefix = "${local.project}-poc"
    domain           = "mydomain.io"
    pri_domain       = "my.local"
    tags             = {
      Project = local.project
    }
  }
}

module "s3DestFirst" {
  source    = "../../"
  providers = {
    aws = aws.replica
  }
  context           = local.context
  bucket_name       = "${local.bucket_name}-first-dest"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

module "s3DestSecond" {
  source    = "../../"
  providers = {
    aws = aws.replica
  }
  context           = local.context
  bucket_name       = "${local.bucket_name}-second-dest"
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
  enable_replication = true
  replication_rules  = [
    {
      id     = "first-rule"
      status = true
      filter = {
        prefix = "first"
      }
      destination = {
        bucket             = module.s3DestFirst.bucket_arn
        storage_class      = "STANDARD_IA"
        replica_kms_key_id = data.aws_kms_key.replica.arn
      }
      source_selection_criteria = {
        sse_kms_encrypted_objects = {
          enabled = true
        }
      }
    },
    {
      id       = "second-rule"
      status   = true
      priority = 10
      filter   = {
        prefix = "second"
      }
      destination = {
        bucket             = module.s3DestSecond.bucket_arn
        storage_class      = "STANDARD_IA"
        replica_kms_key_id = data.aws_kms_key.replica.arn
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
    module.s3DestFirst,
    module.s3DestSecond
  ]

}
