# tfmodule-aws-s3

Amazon S3 버킷을 생성하는 테라폼 모듈입니다.

## Usage

### Basic

```hcl
module "basic" {
  source            = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-s3.git"
  context           = module.ctx.context
  bucket            = "simple-s3"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
}
```

### Encryption

```hcl
module "enc" {
  source             = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-s3.git"
  context            = module.ctx.context
  bucket             = "simple-enc-s3"
  object_ownership   = "ObjectWriter"
  sse_algorithm      = "aws:kms"
  kms_master_key_id  = data.aws_kms_alias.main.id
  bucket_key_enabled = true
}
```

### LifeCycle

```hcl
module "simple" {
  source                  = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-s3.git"
  context                 = module.ctx.context
  bucket                  = "simple-s3"
  object_ownership        = "ObjectWriter"
  enable_bucket_lifecycle = true
  lifecycle_rules         = [
    {
      id                = "default-rule"
      status            = "Enabled"
      glacier_days      = 180
      deep_archive_days = 365
      expiration_days   = 730
    }
  ]
}
```

### Reflection

```hcl

module "dest" {
  source    = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-s3.git"
  providers = {
    aws = aws.destination
  }
  context           = module.ctx.context
  bucket            = "destination-s3"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
}

module "src" {
  source               = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-s3.git"
  context              = module.ctx.context
  bucket               = "source-s3"
  object_ownership     = "ObjectWriter"
  enable_versioning    = true
  enable_replication   = true
  replication_role_arn = aws_iam_role.replica.arn
  replication_rules    = [
    {
      id          = "all"
      status      = true
      destination = {
        bucket        = module.s3_example_clone.bucket_arn
        storage_class = "STANDARD"
      }
    }
  ]
  depends_on = [module.dest]
}
```

### Bucket with Logging

```hcl
locals {
  enable_log_bucket = true
}

module "s3" {
  source = "../../"

  context = {
    project     = "apple"
    region      = "ap-northeast-2"
    environment = "Production"
    team        = "DevOps"
    domain      = "simple.io"
    pri_domain  = "simple.local"
    tags        = {
      Name = "apple-an2p-simple-s3"
      Team = "DevOps"
    }
  }

  bucket           = "apple-prd-simple-s3"
  object_ownership = "ObjectWriter"
  s3_logs_bucket   = "apple-prd-simple-logging-s3"
  depends_on       = [
    aws_s3_bucket.logs
  ]
}
```

## Input

## Output