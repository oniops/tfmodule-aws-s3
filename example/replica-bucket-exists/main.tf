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

# 복제 대상 버킷 (다른 리전)
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

# 복제 보고서 버킷
module "report" {
  source           = "../../"
  context          = module.ctx.context
  bucket_name      = "ex03-replica-report"
  object_ownership = "ObjectWriter"
  force_destroy    = true
}

# 소스 버킷 (복제 설정 포함)
module "source" {
  source                  = "../../"
  context                 = module.ctx.context
  bucket_name             = "ex03-replica-source"
  object_ownership        = "ObjectWriter"

  # KMS 암호화 설정
  sse_algorithm           = "aws:kms"
  kms_master_key_id       = data.aws_kms_alias.origin.target_key_arn
  bucket_key_enabled      = true

  # 버전 관리 (복제 필수)
  enable_versioning       = true

  # 라이프사이클 규칙
  enable_bucket_lifecycle = true
  lifecycle_rules = [
    {
      id              = "expire-one-year-rule"
      status          = "Enabled"
      expiration_days = 365
    }
  ]

  # 복제 설정
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

      # 실시간 복제 설정
      replication_time = {
        status  = true
        minutes = 15
      }

      # 복제 메트릭
      metrics = {
        status  = true
        minutes = 15
      }

      # KMS 암호화된 객체 복제
      source_selection_criteria = {
        sse_kms_encrypted_objects = {
          enabled = true
        }
      }
    }
  ]

  force_destroy = true

  depends_on = [
    module.target,
    module.report
  ]
}