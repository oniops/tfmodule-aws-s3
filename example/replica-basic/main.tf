locals {
  bucket_name = "hello"

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

module "s3DemoDest" {
  source    = "../../"
  providers = {
    aws = aws.replica
  }
  context           = local.context
  bucket_name       = "${local.bucket_name}-destination"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

module "s3Demo" {
  source = "../../"

  context                 = local.context
  bucket_name             = local.bucket_name
  object_ownership        = "ObjectWriter"
  sse_algorithm           = "aws:kms"
  kms_master_key_id       = data.aws_kms_key.origin.arn
  bucket_key_enabled      = true
  enable_versioning       = true
  enable_replication = true
  replication_rules  = [
    {
      id                        = "default-replica-rule"
      status                    = true
      delete_marker_replication = false
      destination               = {
        bucket             = module.s3DemoDest.bucket_arn
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

  depends_on = [module.s3DemoDest]
}
