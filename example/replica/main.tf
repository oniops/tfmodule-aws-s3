locals {
  context = {
    project       = "demo"
    region        = "ap-northeast-2"
    name_prefix   = "demo-an2p"
    bucket_prefix = "demo-poc"
    tags          = {
      Project = "demo"
    }
  }
}

module "replica" {
  source    = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-s3.git"
  providers = {
    aws = aws.replica
  }
  context           = local.context
  bucket            = "${local.context.name_prefix}-replica-s3"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
}

module "origin" {
  source = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-s3.git"

  context           = local.context
  bucket            = "${local.context.name_prefix}-origin-s3"
  object_ownership        = "ObjectWriter"
  sse_algorithm           = "aws:kms"
  kms_master_key_id       = data.aws_kms_key.origin.arn
  bucket_key_enabled      = true
  enable_versioning       = true
  enable_replication      = true
  replication_role_arn    = aws_iam_role.replica.arn
  replication_rules       = [
    {
      id                        = "all"
      status                    = true
      delete_marker_replication = true
      destination               = {
        bucket             = module.replica.bucket_arn
        storage_class      = "STANDARD"
        replica_kms_key_id = data.aws_kms_key.replica.arn
        replication_time = {
          status  = true
          minutes = 15
        }
        metrics = {
          status  = true
          minutes = 15
        }
      }

      source_selection_criteria = {
        sse_kms_encrypted_objects = {
          enabled = true
        }
      }

    }
  ]
  depends_on = [module.replica]
}
