# tfmodule-aws-s3
Amazon S3 버킷을 생성하는 테라폼 모듈입니다.

## Usage

### Basic

```
module "s3" {
  source = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-s3.git"

  context          = {
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
  
  bucket           = "simple-s3"
  object_ownership = "ObjectWriter"
}
```

### Bucket with Logging

```
locals {
  enable_log_bucket = true
}

resource "aws_s3_bucket" "logs" {
  count         = local.enable_log_bucket ? 1 : 0
  bucket        = "apple-prd-simple-logging-s3"
  force_destroy = true

  lifecycle {
    ignore_changes = [
      grant
    ]
  }

  tags = {
    Name = "apple-prd-simple-logging-s3"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  count         = local.enable_log_bucket ? 1 : 0
  bucket = try(aws_s3_bucket.logs[0].id, "")
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count         = local.enable_log_bucket ? 1 : 0
  bucket = try(aws_s3_bucket.logs[0].id, "")
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count         = local.enable_log_bucket ? 1 : 0

  bucket = try(aws_s3_bucket.logs[0].id, "")

  rule {
    id     = "one-year-rule"
    status = "Enabled"

    expiration {
      days = 365
    }
  }

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