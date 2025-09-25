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
  bucket_name       = "exr401-report-replica-target"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

# 복제 보고서 버킷
module "report" {
  source           = "../../"
  context          = module.ctx.context
  bucket_name      = "exr401-report-replica-report"
  object_ownership = "ObjectWriter"
  force_destroy    = true
}

module "source" {
  source                        = "../../"
  context                       = module.ctx.context
  bucket_name                   = "exr401-report-replica-source"
  object_ownership              = "ObjectWriter"
  bucket_key_enabled            = true
  enable_versioning             = true
  enable_replication            = true
  replication_report_bucket_arn = module.report.bucket_arn
  replication_rules = [
    {
      id                          = "report-replica-rule"
      status                      = true
      delete_marker_replication   = false
      
      # 중요: existing_object_replication을 false 또는 생략
      # `Batch Operations`으로 별도 처리
      existing_object_replication = false
      
      destination = {
        bucket        = module.target.bucket_arn
        storage_class = null
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

    }
  ]

  # PoC 검증 용도만 `force_destroy` 속성을 `true`로 하세요.
  force_destroy = true

  depends_on = [
    module.target,
    module.report
  ]
}
