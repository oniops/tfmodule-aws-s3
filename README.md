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
- Terraform >= 1.7.0
- AWS Provider >= 6.0
- AWS 계정 및 적절한 IAM 권한

### 빠른 시작
```bash
# 예제 저장소 클론 (예제는 tfmodule-examples 저장소에서 관리)
git clone https://github.com/oniops/tfmodule-examples.git

# 모듈 사용 예제
cd tfmodule-examples/tfmodule-aws-s3/basic

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
├── variables.tf                               # 버킷 공통 변수 (이름, 퍼블릭 액세스, 소유권)
├── variables-context.tf                       # 컨텍스트 변수
├── variables-encryption.tf                    # 암호화 변수
├── variables-versioning.tf                    # 버전 관리 / Object Lock 변수
├── variables-lifecycle.tf                     # 라이프사이클 변수
├── variables-replication.tf                   # 복제 변수
├── variables-logging.tf                       # 액세스 로깅 변수
├── variables-policy.tf                        # 버킷 정책 변수
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
└── templates/                                 # 버킷/IAM 정책 템플릿 (*.tftpl)
```

### 예제

예제는 이 저장소가 아닌 [oniops/tfmodule-examples](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/) 저장소의 `tfmodule-aws-s3/` 디렉토리에서 관리합니다.

| 예제 | 설명 |
|------|------|
| [basic](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/basic/) | Basic 버킷 |
| [cloudtrail](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/cloudtrail/) | CloudTrail 로그 버킷 |
| [custom-policy](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/custom-policy/) | 사용자 정의 버킷 정책 |
| [lifecycle](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/lifecycle/) | 라이프사이클 설정 |
| [replica-basic](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/replica-basic/) | 기본 Cross-Region 복제 |
| [replica-filtered-kms](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/replica-filtered-kms/) | 필터 + KMS 암호화 복제 |
| [replica-multiple](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/replica-multiple/) | 다중 복제 규칙 |
| [replica-reporting](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/replica-reporting/) | Batch Operations 복제 |

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

빌트인 정책 플래그를 켜는 것만으로 자주 쓰는 statement 들이 자동으로 합쳐져 적용됩니다. 여러 정책을 동시에 켜도 statement 의 형태가 서로 달라도 (Action/Resource 가 string vs list, Principal 이 `"*"` vs object 등) 하나의 버킷 정책으로 안전하게 병합됩니다.

```hcl
# HTTPS 전송 강제
attach_deny_insecure_transport_policy = true

# 잘못된 암호화 헤더 거부
attach_deny_incorrect_encryption_headers = true

# ALB / NLB / ELB / S3 액세스 로그 / Inspector 리포트 등 서비스 로그 수집
attach_lb_log_delivery_policy      = true
attach_elb_log_delivery_policy     = true
attach_access_log_delivery_policy  = true
attach_aws_inspector_report_policy = true

# VPC 엔드포인트 전용 액세스
source_vpce = "vpce-1234567890abcdef0"

# CloudFront OAC 액세스 허용
cloudfront_distributions_arn = [
  "arn:aws:cloudfront::111122223333:distribution/ABCDEF123456"
]
```

#### 커스텀 정책 (`attach_custom_policy`)

`attach_custom_policy` 는 `any` 타입으로 받기 때문에 다음 세 가지 형식을 모두 지원합니다. 빌트인 정책과 함께 사용하면 모든 statement 가 하나의 `aws_s3_bucket_policy` 로 병합되어 적용됩니다.

```hcl
# 1) 권장: native HCL statement 객체 리스트
attach_custom_policy = [
  {
    Sid       = "AllowCloudFrontDistribution"
    Effect    = "Allow"
    Principal = { Service = "cloudfront.amazonaws.com" }
    Action    = "s3:GetObject"
    Resource  = "arn:aws:s3:::my-bucket/*"
    Condition = {
      ArnLike = {
        "aws:SourceArn" = "arn:aws:cloudfront::111122223333:distribution/*"
      }
    }
  },
  {
    Sid       = "AllowServiceLogWrite"
    Effect    = "Allow"
    Principal = { Service = ["logdelivery.elasticloadbalancing.amazonaws.com"] }
    Action    = ["s3:PutObject", "s3:PutObjectAcl"]
    Resource  = ["arn:aws:s3:::my-bucket", "arn:aws:s3:::my-bucket/*"]
  },
]

# 2) 단일 statement 객체
attach_custom_policy = {
  Sid       = "AllowCloudFrontDistribution"
  Effect    = "Allow"
  Principal = { Service = "cloudfront.amazonaws.com" }
  Action    = "s3:GetObject"
  Resource  = "arn:aws:s3:::my-bucket/*"
}

# 3) 기존 JSON 문자열 (하위호환)
attach_custom_policy = jsonencode([
  {
    Sid    = "Example"
    Effect = "Allow"
    # ...
  }
])
```

> 동일 statement 내에서 `Action` / `Resource` / `Principal.Service` 등은 단일 값이든 리스트든 자유롭게 섞어 쓸 수 있습니다. 빈 statement 를 주거나 `attach_custom_policy = null` 로 두면 적용되지 않습니다.

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
lifecycle_rules = {
  # map key = rule ID
  "archive-old-data" = {
    enabled = true  # 기본값 true

    # 필터링 - 조건이 2개 이상이면 and 사용
    filter = {
      and = {
        prefix = "logs/"
        tags   = { Archive = "true" }
      }
    }

    # 스토리지 클래스 전환 (STORAGE_CLASS = 경과 일수)
    transitions = {
      STANDARD_IA         = 30
      INTELLIGENT_TIERING = 60
      GLACIER_IR          = 90
      GLACIER             = 180
      DEEP_ARCHIVE        = 365
    }

    # 객체 만료
    expiration_days = 730

    # 비현재 버전 (버전 관리 필요)
    noncurrent_version_transitions     = { GLACIER = 30 }
    noncurrent_version_expiration_days = 365
  }
}
```

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| (map key) | string | - | 규칙 ID |
| `enabled` | bool | `true` | 규칙 활성화 여부 |
| `filter` | object | `{}` (전체 객체) | `prefix`, `tag = { key, value }`, `object_size_greater_than`, `object_size_less_than`, `and = { prefix, tags, object_size_* }` 중 선택. `and` 는 다른 조건과 함께 쓸 수 없음 |
| `transitions` | map(number) | `{}` | 스토리지 클래스 → 전환 일수. 허용 key: `STANDARD_IA`, `INTELLIGENT_TIERING`, `ONEZONE_IA`, `GLACIER_IR`, `GLACIER`, `DEEP_ARCHIVE` |
| `expiration_days` | number | `null` | 객체 만료 일수 |
| `noncurrent_version_transitions` | map(number) | `{}` | 비현재 버전 스토리지 클래스 → 전환 일수 |
| `noncurrent_version_expiration_days` | number | `null` | 비현재 버전 만료 일수 |

> ⚠️ 정의되지 않은 속성(예: 오타 `expiraton_days`)은 Terraform 타입 변환 과정에서 **오류 없이 무시**됩니다. `terraform plan` 결과에 의도한 블록이 렌더링되는지 반드시 확인하세요.

#### Object Lock
```hcl
# 규정 준수 모드
object_lock_enabled = true
object_lock_mode    = "COMPLIANCE"
object_lock_days    = 365
```

### 3. 🔄 복제 (Replication)

S3 복제를 통해 버킷 간 자동 또는 수동으로 객체를 복사할 수 있습니다. Cross-Region 백업, 규정 준수, 성능 최적화 등 다양한 용도로 활용됩니다.

#### 실시간 복제 (신규 객체)
```hcl
enable_versioning  = true  # 필수
enable_replication = true

replication_rules = {
  # map key = rule ID
  "realtime-replication" = {
    priority                  = 0      # 필수, 규칙마다 고유
    delete_marker_replication = false

    destination = {
      bucket        = "arn:aws:s3:::target-bucket"
      storage_class = "STANDARD_IA"  # 생략 시 원본과 동일

      # 15분 내 복제 보장 (RTC) - metrics 필요
      replication_time = true
      metrics          = true
    }
  }
}
```

| 속성 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| (map key) | string | - | 규칙 ID |
| `priority` | number | **필수** | 규칙 우선순위 (규칙마다 고유) |
| `enabled` | bool | `true` | 규칙 활성화 여부 |
| `delete_marker_replication` | bool | `false` | 삭제 마커 복제 |
| `existing_object_replication` | bool | `false` | 기존 객체 복제 (AWS Support 활성화 필요) |
| `filter` | object | `{}` (전체 객체) | `prefix`, `tag = { key, value }`, `and = { prefix, tags }` 중 선택. `and` 는 다른 조건과 함께 쓸 수 없음 |
| `destination.bucket` | string | **필수** | 대상 버킷 ARN |
| `destination.storage_class` | string | `null` | 대상 스토리지 클래스 |
| `destination.account_id` | string | `null` | 대상 계정 ID (Cross-Account) |
| `destination.owner_override` | bool | `false` | 복제본 소유자를 대상 계정으로 변경 (`account_id` 필요) |
| `destination.replica_kms_key_id` | string | `null` | 대상 KMS 키 ARN (`source_selection_criteria.sse_kms_encrypted_objects = true` 필요) |
| `destination.replication_time` | bool | `false` | S3 RTC (15분) 활성화 (`metrics = true` 필요) |
| `destination.metrics` | bool | `false` | 복제 메트릭 활성화 |
| `source_selection_criteria.sse_kms_encrypted_objects` | bool | `false` | SSE-KMS 암호화 객체 복제 |
| `source_selection_criteria.replica_modifications` | bool | `false` | 복제본 메타데이터 변경 동기화 |

#### Batch Operations (기존 객체)
```hcl
# 기존 객체 복제를 위한 리포트 버킷 설정
replication_report_bucket_arn = "arn:aws:s3:::report-bucket"

replication_rules = {
  "batch-replication" = {
    priority                    = 0
    existing_object_replication = false  # Batch로 별도 처리

    destination = {
      bucket = "arn:aws:s3:::target-bucket"
    }
  }
}
```

📖 **[S3 복제 완벽 가이드](./HELP-REPLICA.md)** - 복제 설정, Batch Operations, 예제 시나리오, 문제 해결 등 상세 정보

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
| `lifecycle_rules` | `{}` | 라이프사이클 규칙 map (key = rule ID) |
| `replication_rules` | `{}` | 복제 규칙 map (key = rule ID) |

### 정책 관련 변수

플래그 중 하나라도 `true` 이거나 ARN/VPCE/커스텀 정책이 지정되면 모듈이 자동으로 `aws_s3_bucket_policy` 를 생성하고 모든 statement 를 하나로 병합합니다.

| 변수명 | 타입 | 기본값 | 설명 |
|--------|------|--------|------|
| `attach_deny_insecure_transport_policy` | bool | `false` | HTTPS 가 아닌 요청 차단 |
| `attach_deny_incorrect_encryption_headers` | bool | `false` | 잘못된 암호화 헤더 요청 거부 |
| `attach_lb_log_delivery_policy` | bool | `false` | ALB / NLB 액세스 로그 수신 허용 |
| `attach_elb_log_delivery_policy` | bool | `false` | Classic ELB 액세스 로그 수신 허용 |
| `attach_access_log_delivery_policy` | bool | `false` | S3 서버 액세스 로그 수신 허용 |
| `attach_aws_inspector_report_policy` | bool | `false` | AWS Inspector 리포트 익스포트 허용 |
| `cloudfront_distributions_arn` | set(string) | `[]` | CloudFront OAC 접근을 허용할 배포 ARN 목록 |
| `source_vpce` | string | `null` | 지정된 VPC 엔드포인트로만 객체 읽기 허용 |
| `attach_custom_policy` | any | `null` | 사용자 정의 statement (list/object/JSON 문자열 모두 허용) |

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
# 컨텍스트 모듈 사용 (권장)
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.5"
  context = {
    project     = "myproject"
    region      = "ap-northeast-2"
    environment = "development"
    team        = "platform"
    domain      = "example.com"
    pri_domain  = "internal.example.com"
  }
}

module "simple_bucket" {
  source = "git::https://github.com/oniops/tfmodule-aws-s3.git"

  context          = module.ctx.context
  bucket_name      = "application-data"
  object_ownership = "BucketOwnerEnforced"
}
```

### 2. 보안이 강화된 버킷

```hcl
module "secure_bucket" {
  source = "git::https://github.com/oniops/tfmodule-aws-s3.git"

  context          = module.ctx.context
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
  source = "git::https://github.com/oniops/tfmodule-aws-s3.git"

  context          = module.ctx.context
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
  lifecycle_rules = {
    "delete-old-logs" = {
      filter = {
        prefix = "logs/"
      }
      expiration_days = 90
    }
  }
}
```

### 4. Cross-Region 복제 설정 (KMS 암호화 포함)

```hcl
# 컨텍스트 모듈 (tfmodule-context 사용)
module "ctx" {
  source = "git::https://github.com/oniops/tfmodule-context.git?ref=v1.3.5"
  context = {
    project     = "demo"
    region      = "ap-northeast-2"
    environment = "Production"
    team        = "DevOps"
    domain      = "example.com"
    pri_domain  = "internal.example.com"
  }
}

# 복제 대상 버킷 (다른 리전)
module "target" {
  source = "git::https://github.com/oniops/tfmodule-aws-s3.git"
  providers = {
    aws = aws.replica
  }
  context           = module.ctx.context
  bucket_name       = "dr-replica-target"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
  force_destroy     = true
}

# 소스 버킷 (KMS 암호화 및 복제 설정)
module "source" {
  source = "git::https://github.com/oniops/tfmodule-aws-s3.git"

  context            = module.ctx.context
  bucket_name        = "production-source"
  object_ownership   = "ObjectWriter"

  # KMS 암호화
  sse_algorithm      = "aws:kms"
  kms_master_key_id  = data.aws_kms_alias.origin.target_key_arn
  bucket_key_enabled = true

  # 버전 관리 (복제 필수)
  enable_versioning  = true

  # 복제 설정
  enable_replication = true
  replication_rules = {
    "dr-replication" = {
      priority                  = 0
      delete_marker_replication = false

      destination = {
        bucket             = module.target.bucket_arn
        storage_class      = "STANDARD_IA"
        replica_kms_key_id = data.aws_kms_alias.replica.target_key_arn
      }

      # KMS 암호화된 객체 복제
      source_selection_criteria = {
        sse_kms_encrypted_objects = true
      }
    }
  }

  force_destroy = true
  depends_on    = [module.target]
}
```

### 5. 커스텀 정책 (빌트인 정책과 혼합)

빌트인 정책 플래그와 사용자 정의 statement 를 한 번에 적용한 예시입니다. `attach_custom_policy` 는 native HCL 리스트를 그대로 전달할 수 있으며, statement 들의 구조가 서로 달라도(예: `Action` 이 string vs list, `Principal.Service` 가 string vs list) 정상적으로 병합됩니다.

```hcl
module "s3_with_custom_policy" {
  source = "git::https://github.com/oniops/tfmodule-aws-s3.git"

  context          = module.ctx.context
  bucket           = "my-app-bucket"
  object_ownership = "BucketOwnerEnforced"

  # 빌트인: HTTPS 강제
  attach_deny_insecure_transport_policy = true

  # 사용자 정의 statement 들
  attach_custom_policy = [
    {
      Sid       = "AllowCloudFrontDistribute"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::my-app-bucket/*"
      Condition = {
        ArnLike = {
          "aws:SourceArn" = "arn:aws:cloudfront::111122223333:distribution/*"
        }
      }
    },
    {
      Sid       = "AllowServiceLogWrite"
      Effect    = "Allow"
      Principal = {
        Service = [
          "logdelivery.elasticloadbalancing.amazonaws.com",
          "cloudwatch.amazonaws.com",
        ]
      }
      Action = ["s3:PutObject", "s3:PutObjectAcl"]
      Resource = [
        "arn:aws:s3:::my-app-bucket",
        "arn:aws:s3:::my-app-bucket/*",
      ]
    },
  ]
}
```

전체 예제는 [`tfmodule-aws-s3/custom-policy/`](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/custom-policy/) 를 참고하세요.

### 6. CloudFront 배포용 정적 웹사이트 버킷

```hcl
module "static_website" {
  source = "git::https://github.com/oniops/tfmodule-aws-s3.git"

  context          = module.ctx.context
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
  lifecycle_rules = {
    "cleanup-old-versions" = {
      noncurrent_version_expiration_days = 30
    }
  }
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

#### 5. 커스텀 정책 statement 가 적용되지 않음
**원인**: `attach_custom_policy` 가 `null` 이거나 빈 리스트(`[]`) 인 경우 모듈이 정책을 생성하지 않습니다. 또한 native HCL 리스트로 전달할 때 키 이름은 IAM 표준(`Sid`, `Effect`, `Principal`, `Action`, `Resource`, `Condition`) 을 그대로 사용해야 합니다.

**해결책**: `attach_custom_policy` 에 최소 하나 이상의 statement 객체를 포함한 리스트를 넘기거나, `terraform plan -out=tfplan && terraform show -json tfplan | jq '.. | .Statement? // empty'` 로 병합 결과를 검증하세요.

#### 6. 정책 statement 구조가 달라 plan 이 실패
이전 버전의 일부 모듈에서는 `tolist(jsondecode(...))` + `concat()` 패턴으로 statement 를 합치다가 `Action` / `Resource` / `Principal` 의 형태가 다르면 type-unification 에러가 났습니다. 본 모듈은 `flatten([for s : jsondecode(s)])` + `try()` 기반으로 이질적 statement 를 그대로 병합하므로 이 문제가 발생하지 않습니다. 그래도 발생한다면 모듈 버전이 최신인지 확인하세요.

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

# 예제 테스트 (tfmodule-examples 저장소)
cd tfmodule-examples/tfmodule-aws-s3/lifecycle
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