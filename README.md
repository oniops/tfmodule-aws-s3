# tfmodule-aws-s3

Amazon S3 버킷을 생성하는 테라폼 모듈입니다.

## 📚 목차
- [시작하기](#시작하기)
- [모듈 구조](#모듈-구조)
- [주요 기능](#주요-기능)
- [사용 방법](#사용-방법)
- [변수 설명](#변수-설명)
- [출력값](#출력값)
- [예제](#예제)
- [문제 해결](#문제-해결)
- [기여 가이드](#기여-가이드)

## 시작하기

### 필수 요구사항
- Terraform >= 1.0
- AWS Provider >= 4.0
- AWS 계정 및 적절한 IAM 권한

### 빠른 시작
```bash
# 저장소 클론
git clone https://github.com/your-org/tfmodule-aws-s3.git

# 모듈 사용 예제
cd example/lifecycle

# Terraform 초기화
terraform init

# 실행 계획 확인
terraform plan

# 리소스 생성
terraform apply
```

## 모듈 구조

```
tfmodule-aws-s3/
├── main.tf                                    # S3 버킷 기본 리소스
├── variables.tf                               # 모듈 입력 변수
├── variables-context.tf                       # 컨텍스트 변수
├── outputs.tf                                 # 모듈 출력값
├── versions.tf                                # Terraform 및 Provider 버전
│
├── s3-encrypt.tf                              # 암호화 설정
├── s3-versioning.tf                           # 버전 관리 설정
├── s3-lifecycle.tf                            # 라이프사이클 관리
├── s3-replicas.tf                             # 복제 설정
├── s3-replicas-role.tf                        # 복제용 IAM 역할
├── s3-logs.tf                                 # 로깅 설정
├── s3-policies.tf                             # 버킷 정책 통합
│
├── s3-policy-allow-vpce.tf                    # VPC 엔드포인트 정책
├── s3-policy-allow-cloudfront-oac.tf          # CloudFront OAC 정책
├── s3-policy-allow-access-log-delivery.tf     # S3 액세스 로그 정책
├── s3-policy-allow-lb-log-delivery.tf         # ALB/NLB 로그 정책
├── s3-policy-allow-elb-log-delivery.tf        # ELB 로그 정책
├── s3-policy-allow-aws-inspector.tf           # AWS Inspector 정책
├── s3-policy-deny-insecure-transport.tf       # HTTP 차단 정책
├── s3-policy-deny-incorrect-encryption.tf     # 잘못된 암호화 차단
│
└── example/                                   # 사용 예제
    ├── cloudtrail/                            # CloudTrail 로그 버킷
    ├── lifecycle/                             # 라이프사이클 설정
    ├── replica-basic/                         # 기본 복제
    ├── replica-existing-objects/              # 기존 객체 복제
    └── replica-multiple/                      # 다중 복제 규칙
```

## 주요 기능

### 1. 🔒 보안 기능

#### 암호화
```hcl
# SSE-S3 (기본 암호화)
sse_algorithm = "AES256"

# SSE-KMS (KMS 키 사용)
sse_algorithm      = "aws:kms"
kms_master_key_id  = aws_kms_key.s3.id
bucket_key_enabled = true

# DSSE-KMS (이중 암호화)
sse_algorithm = "aws:kms:dsse"
```

#### 퍼블릭 액세스 차단
```hcl
# 기본값: 모든 퍼블릭 액세스 차단
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true
```

#### 버킷 정책
```hcl
# HTTPS 전송 강제
attach_deny_insecure_transport_policy = true

# VPC 엔드포인트 전용 액세스
source_vpce = "vpce-1234567890abcdef0"

# CloudFront OAC 액세스 허용
cloudfront_distributions_arn = [
  "arn:aws:cloudfront::111122223333:distribution/ABCDEF123456"
]
```

### 2. 📊 데이터 관리

#### 버전 관리
```hcl
# 간단한 활성화
enable_versioning = true

# 상세 설정
versioning = {
  status     = "Enabled"  # Enabled, Suspended, Disabled
  mfa_delete = "Disabled"
}
```

#### 라이프사이클 관리
```hcl
enable_bucket_lifecycle = true
lifecycle_rules = [
  {
    id                = "archive-old-data"
    status            = "Enabled"

    # 스토리지 클래스 전환
    standard_ia_days          = 30
    intelligent_tiering_days  = 60
    glacier_ir_days           = 90
    glacier_days              = 180
    deep_archive_days         = 365

    # 객체 만료
    expiration_days = 730

    # 필터링
    filter = {
      prefix = "logs/"
      tag = {
        Archive = "true"
      }
    }
  }
]
```

#### Object Lock
```hcl
# 규정 준수 모드
object_lock_enabled = true
object_lock_mode    = "COMPLIANCE"
object_lock_days    = 365
```

### 3. 🔄 복제

```hcl
enable_versioning  = true  # 필수
enable_replication = true

replication_rules = [
  {
    id                        = "cross-region-backup"
    status                    = true
    priority                  = 1
    delete_marker_replication = true

    destination = {
      bucket        = "arn:aws:s3:::backup-bucket"
      storage_class = "GLACIER_IR"

      # KMS 암호화된 객체 복제
      replica_kms_key_id = aws_kms_key.replica.arn
    }

    # 필터
    filter = {
      prefix = "important/"
    }

    # KMS 암호화된 소스 객체 복제
    source_selection_criteria = {
      sse_kms_encrypted_objects = {
        enabled = true
      }
    }
  }
]
```

### 4. 📝 로깅

```hcl
# S3 액세스 로깅
s3_logs_bucket = "my-log-bucket"
s3_logs_prefix = "logs/my-bucket/"

# ALB/NLB 로그 수집
attach_lb_log_delivery_policy = true

# ELB 로그 수집
attach_elb_log_delivery_policy = true
```

## 변수 설명

### 필수 변수

| 변수명 | 타입 | 설명 |
|--------|------|------|
| `context` | object | 프로젝트 컨텍스트 정보 (project, region, account_id 등) |
| `object_ownership` | string | 객체 소유권 설정 (BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced) |

### 주요 선택 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| `create` | `true` | 리소스 생성 여부 |
| `bucket` | `null` | 전체 버킷 이름 (설정 시 bucket_name 무시) |
| `bucket_name` | `null` | 버킷 이름 (prefix와 suffix 자동 추가) |
| `force_destroy` | `false` | 객체가 있어도 버킷 삭제 허용 |
| `sse_algorithm` | `"AES256"` | 암호화 알고리즘 |
| `enable_versioning` | `false` | 버전 관리 활성화 |
| `enable_bucket_lifecycle` | `false` | 라이프사이클 규칙 활성화 |
| `enable_replication` | `false` | 복제 활성화 |

## 출력값

| 출력명 | 설명 |
|--------|------|
| `bucket_name` | 버킷 전체 이름 |
| `bucket_simple_name` | 버킷 간단한 이름 (prefix/suffix 제외) |
| `bucket_id` | 버킷 ID |
| `bucket_arn` | 버킷 ARN |
| `bucket_domain_name` | 버킷 도메인 이름 |
| `bucket_regional_domain_name` | 버킷 지역별 도메인 이름 |
| `versioning_status` | 버전 관리 상태 |
| `bucket_policy` | 적용된 버킷 정책 JSON |

## 예제

### 1. 기본 버킷 생성

```hcl
module "simple_bucket" {
  source = "git::https://github.com/your-org/tfmodule-aws-s3.git"

  context = {
    project          = "myproject"
    region           = "ap-northeast-2"
    account_id       = "123456789012"
    name_prefix      = "dev"
    s3_bucket_prefix = "myorg"
    environment      = "development"
    team             = "platform"
    domain           = "example.com"
    pri_domain       = "internal.example.com"
    tags = {
      Environment = "dev"
      Team        = "platform"
    }
  }

  bucket_name      = "application-data"
  object_ownership = "BucketOwnerEnforced"
}
```

### 2. 보안이 강화된 버킷

```hcl
module "secure_bucket" {
  source = "./modules/tfmodule-aws-s3"

  context          = local.context
  bucket_name      = "sensitive-data"
  object_ownership = "BucketOwnerEnforced"

  # 암호화
  sse_algorithm      = "aws:kms"
  kms_master_key_id  = aws_kms_key.s3.id
  bucket_key_enabled = true

  # 보안 정책
  attach_deny_insecure_transport_policy    = true
  attach_deny_incorrect_encryption_headers = true

  # 버전 관리
  enable_versioning = true
  versioning = {
    status     = "Enabled"
    mfa_delete = "Enabled"
  }

  # Object Lock
  object_lock_enabled = true
  object_lock_mode    = "COMPLIANCE"
  object_lock_days    = 90
}
```

### 3. 로그 수집 버킷

```hcl
module "log_bucket" {
  source = "./modules/tfmodule-aws-s3"

  context          = local.context
  bucket_name      = "application-logs"
  object_ownership = "BucketOwnerPreferred"

  # ALB 로그 수집
  attach_lb_log_delivery_policy = true

  # S3 액세스 로그 수집
  attach_access_log_delivery_policy = true
  access_log_delivery_policy_source_buckets = [
    "arn:aws:s3:::production-app-bucket",
    "arn:aws:s3:::production-static-bucket"
  ]

  # 라이프사이클 - 오래된 로그 삭제
  enable_bucket_lifecycle = true
  lifecycle_rules = [
    {
      id              = "delete-old-logs"
      status          = "Enabled"
      expiration_days = 90

      filter = {
        prefix = "logs/"
      }
    }
  ]
}
```

### 4. 재해 복구를 위한 복제 설정

```hcl
# 대상 버킷 (다른 리전)
module "replica_bucket" {
  source = "./modules/tfmodule-aws-s3"
  providers = {
    aws = aws.dr_region
  }

  context           = local.dr_context
  bucket_name       = "dr-replica"
  object_ownership  = "BucketOwnerEnforced"
  enable_versioning = true
}

# 소스 버킷 (복제 설정)
module "source_bucket" {
  source = "./modules/tfmodule-aws-s3"

  context           = local.context
  bucket_name       = "production-data"
  object_ownership  = "BucketOwnerEnforced"
  enable_versioning = true

  # 복제 설정
  enable_replication = true
  replication_rules = [
    {
      id                        = "dr-replication"
      status                    = true
      priority                  = 1
      delete_marker_replication = true

      destination = {
        bucket        = module.replica_bucket.bucket_arn
        storage_class = "STANDARD_IA"
      }

      # 실시간 복제
      destination = {
        replication_time = {
          status = "Enabled"
          minutes = 15
        }
        metrics = {
          status = "Enabled"
          minutes = 15
        }
      }
    }
  ]

  depends_on = [module.replica_bucket]
}
```

### 5. CloudFront 배포용 정적 웹사이트 버킷

```hcl
module "static_website" {
  source = "./modules/tfmodule-aws-s3"

  context          = local.context
  bucket_name      = "static-website"
  object_ownership = "BucketOwnerEnforced"

  # CloudFront OAC 액세스 허용
  cloudfront_distributions_arn = [
    aws_cloudfront_distribution.website.arn
  ]

  # 버전 관리
  enable_versioning = true

  # 캐시 최적화를 위한 라이프사이클
  enable_bucket_lifecycle = true
  lifecycle_rules = [
    {
      id     = "cleanup-old-versions"
      status = "Enabled"

      noncurrent_version_expiration_days = 30
    }
  ]
}
```

## 문제 해결

### 자주 발생하는 문제

#### 1. 버킷 이름 충돌
```
Error: Error creating S3 bucket: BucketAlreadyExists
```
**해결책**: S3 버킷 이름은 전역적으로 고유해야 합니다. `bucket_name`을 변경하거나 `context.s3_bucket_prefix`를 수정하세요.

#### 2. 복제 실패
```
Error: Versioning must be enabled to configure replication
```
**해결책**: 복제를 사용하려면 반드시 `enable_versioning = true`를 설정하세요.

#### 3. 라이프사이클 필터 오류
```
Error: At least one filter condition is required
```
**해결책**: `filter` 블록 사용 시 `prefix`, `tag`, `object_size_greater_than`, `object_size_less_than` 중 하나 이상을 지정하세요.

#### 4. Object Lock 변경 불가
```
Error: Object Lock configuration cannot be changed after bucket creation
```
**해결책**: Object Lock은 버킷 생성 시에만 설정 가능합니다. 새 버킷을 생성해야 합니다.

### 디버깅 팁

```bash
# Terraform 디버그 로그 활성화
export TF_LOG=DEBUG
terraform plan

# 특정 리소스만 확인
terraform state show module.my_bucket.aws_s3_bucket.this[0]

# 버킷 정책 검증
aws s3api get-bucket-policy --bucket my-bucket | jq .
```

## 기여 가이드

### 개발 환경 설정

```bash
# pre-commit 설치
pip install pre-commit
pre-commit install

# Terraform 포맷팅
terraform fmt -recursive

# 문서 자동 생성
terraform-docs markdown . > TERRAFORM_DOCS.md
```

### 테스트

```bash
# 구문 검증
terraform validate

# 포맷 확인
terraform fmt -check -recursive

# 계획 실행 (dry-run)
terraform plan

# 예제 테스트
cd example/lifecycle
terraform init && terraform plan
```

### 커밋 메시지 규칙

```
type(scope): subject

- feat: 새로운 기능
- fix: 버그 수정
- docs: 문서 변경
- style: 코드 포맷팅
- refactor: 리팩토링
- test: 테스트 추가
- chore: 빌드 또는 보조 도구 변경

예시:
feat(lifecycle): Add support for Glacier Instant Retrieval
fix(replication): Correct filter configuration for multiple rules
docs(readme): Add CloudFront OAC configuration example
```

## 지원 및 문의

- **버그 리포트**: [GitHub Issues](https://github.com/oniops/tfmodule-aws-s3/issues)
- **보안 문제**: infraops_oni@opsnow.com
- **문서**: [Wiki](https://github.com/oniops/tfmodule-aws-s3/wiki)



## 라이선스

이 프로젝트는 [MIT 라이선스](LICENSE)를 따릅니다.

## 변경 이력

📌 **참고**: 이 모듈은 지속적으로 업데이트됩니다. 최신 버전과 기능은 [릴리즈 페이지](https://github.com/oniops/tfmodule-aws-s3/tags)에서 확인하세요.