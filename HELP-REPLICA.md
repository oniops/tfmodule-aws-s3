# S3 복제(Replication) 완벽 가이드

## 목차
1. [개요](#개요)
2. [복제 방식 비교](#복제-방식-비교)
3. [실시간 복제 (Replication Rules)](#실시간-복제-replication-rules)
4. [배치 복제 (Batch Operations)](#배치-복제-batch-operations)
5. [하이브리드 접근법](#하이브리드-접근법)
6. [예제 시나리오](#예제-시나리오)
7. [문제 해결](#문제-해결)
8. [FAQ](#faq)

## 개요

S3 복제는 버킷 간 객체를 자동 또는 수동으로 복사하는 기능입니다. 주요 용도:
- **재해 복구**: 다른 리전으로 데이터 백업
- **규정 준수**: 데이터 복사본 유지
- **성능 최적화**: 지리적으로 가까운 위치에 데이터 복제
- **데이터 통합**: 여러 계정의 데이터를 중앙 집중화

## 복제 방식 비교

| 방식 | 복제 시간 | 대상 객체 | 용도 | 비용 |
|------|----------|----------|------|------|
| **Replication Rules** | 실시간 (초~분) | 신규 객체 | 지속적 동기화 | 낮음 |
| **Replication + RTC** | 15분 내 보장 | 신규 객체 | SLA 필요 시 | 추가 비용 |
| **Batch Operations** | 수동 실행 | 기존 객체 | 일회성 마이그레이션 | Job당 $0.25 |
| **S3 Inventory + Batch** | 24-48시간 | 대량 객체 | 정기 백업 | Job당 $0.25 |

## 실시간 복제 (Replication Rules)

### 기본 설정

```hcl
module "source" {
  source             = "../../"
  context            = module.ctx.context
  bucket_name        = "my-source-bucket"
  enable_versioning  = true  # 필수: 버전 관리 활성화
  enable_replication = true

  # map key = rule ID
  replication_rules = {
    "basic-replication" = {
      priority                  = 0      # 필수, 규칙마다 고유
      delete_marker_replication = false  # 삭제 마커 복제 여부

      destination = {
        bucket        = "arn:aws:s3:::target-bucket"
        storage_class = "STANDARD_IA"  # 생략 시 원본과 동일
      }
    }
  }
}
```

> 입력 스키마 전체와 검증 규칙은 `variables-replication.tf` 의 `replication_rules` 정의를 참고하세요. 잘못된 조합(priority 중복, KMS 복제인데 `sse_kms_encrypted_objects` 미설정, RTC 만 켜고 metrics 를 끔, `owner_override` 인데 `account_id` 없음, `filter.and` 를 다른 조건과 함께 사용)은 `terraform plan` 단계에서 오류로 알려 줍니다.

### 고급 설정

#### 1. RTC (Replication Time Control) - 15분 내 복제 보장

```hcl
replication_rules = {
  "guaranteed-replication" = {
    priority = 0

    destination = {
      bucket = "arn:aws:s3:::target-bucket"

      # 15분 내 복제 보장 (추가 비용 발생, AWS 고정값 15분)
      replication_time = true

      # 복제 메트릭 활성화 (RTC 사용 시 필수)
      metrics = true
    }
  }
}
```

#### 2. 필터링된 복제

```hcl
replication_rules = {
  "filtered-replication" = {
    priority = 0

    # Prefix 기반 필터
    filter = {
      prefix = "important/"
    }

    # 또는 태그 기반 필터 (태그 1개)
    filter = {
      tag = { key = "Replicate", value = "true" }
    }

    # 또는 복합 필터 (AND 조건) - 다른 조건과 함께 쓸 수 없음
    filter = {
      and = {
        prefix = "data/"
        tags = {
          Environment = "Production"
          Replicate   = "true"
        }
      }
    }

    destination = {
      bucket = "arn:aws:s3:::target-bucket"
    }
  }
}
```

#### 3. KMS 암호화 객체 복제

```hcl
replication_rules = {
  "kms-replication" = {
    priority = 0

    destination = {
      bucket             = "arn:aws:s3:::target-bucket"
      replica_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/..."
    }

    # KMS 암호화된 객체만 복제 (replica_kms_key_id 지정 시 필수)
    source_selection_criteria = {
      sse_kms_encrypted_objects = true
    }
  }
}
```

#### 4. Cross-Account 복제

```hcl
replication_rules = {
  "cross-account" = {
    priority = 0

    destination = {
      bucket     = "arn:aws:s3:::other-account-bucket"
      account_id = "987654321098"  # 대상 계정 ID

      # 대상 계정에서 객체 소유권 변경 (account_id 필요)
      owner_override = true
    }
  }
}
```

## 배치 복제 (Batch Operations)

### 기본 구성

```hcl
module "source" {
  source             = "../../"
  enable_replication = true

  # Batch Operations 리포트용 버킷 (필수)
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
}
```

### Batch Job 실행 방법

#### 1. 소량 객체 (수십~수백 개)

```bash
# manifest.csv 수동 생성
cat > manifest.csv <<EOF
source-bucket,file1.txt
source-bucket,file2.txt
source-bucket,folder/file3.txt
EOF

# Batch Job 실행
./create-batch-job.sh
```

#### 2. 중량 객체 (수천~수만 개)

```bash
# AWS CLI로 자동 생성
aws s3api list-objects-v2 \
  --bucket source-bucket \
  --query 'Contents[].[join(`,`, [@, Key])]' \
  --output text | sed 's/^/source-bucket,/' > manifest.csv

# 필터링 예: 30일 이내 수정된 객체
DATE_30_DAYS_AGO=$(date -d "30 days ago" +%Y-%m-%d)
aws s3api list-objects-v2 \
  --bucket source-bucket \
  --query "Contents[?LastModified>='$DATE_30_DAYS_AGO'].[join(',', [@, Key])]" \
  --output text | sed 's/^/source-bucket,/' > manifest-recent.csv
```

#### 3. 대량 객체 (수백만 개 이상)

```bash
# S3 Inventory 설정 (24-48시간 후 자동 생성)
./create-batch-job-with-inventory.sh
```

### Batch Job JSON 구조

> `S3ReplicateObject` 는 파라미터가 없는 작업입니다. 대상 버킷·스토리지 클래스·KMS 키는 소스 버킷의 복제 규칙(`replication_rules`)을 그대로 사용하므로, 복제 규칙을 먼저 만든 뒤 Job 을 실행해야 합니다.

```json
{
  "AccountId": "123456789012",
  "ConfirmationRequired": false,
  "Operation": {
    "S3ReplicateObject": {}
  },
  "Manifest": {
    "Spec": {
      "Format": "S3BatchOperations_CSV_20180820",
      "Fields": ["Bucket", "Key"]
    },
    "Location": {
      "ObjectArn": "arn:aws:s3:::report-bucket/manifest.csv",
      "ETag": "example-etag"
    }
  },
  "RoleArn": "arn:aws:iam::123456789012:role/S3CrrRole",
  "Report": {
    "Bucket": "arn:aws:s3:::report-bucket",
    "Prefix": "batch-reports",
    "Format": "Report_CSV_20180820",
    "Enabled": true,
    "ReportScope": "AllTasks"
  }
}
```

## 하이브리드 접근법

### 권장 마이그레이션 전략

```hcl
# 1단계: 실시간 복제 설정 (신규 객체)
module "source" {
  enable_replication = true

  replication_rules = {
    "ongoing-replication" = {
      priority                    = 0
      existing_object_replication = false  # 중복 방지

      destination = {
        bucket = "arn:aws:s3:::target-bucket"
      }
    }
  }

  replication_report_bucket_arn = module.report.bucket_arn
}
```

```bash
# 2단계: 기존 객체 일회성 복제
./create-batch-job.sh

# 3단계: 복제 상태 확인
./check-replication-status.sh
```

### 중복 복제 방지

S3는 자동으로 중복 복제를 방지합니다:

1. **ReplicationStatus 메타데이터**
   - `COMPLETED`: 이미 복제됨
   - `PENDING`: 복제 대기 중
   - `FAILED`: 복제 실패

2. **중복 방지 메커니즘**
   ```bash
   # 복제 상태 확인
   aws s3api head-object \
     --bucket source-bucket \
     --key object.txt \
     --query ReplicationStatus
   ```

## 예제 시나리오

예제는 [oniops/tfmodule-examples](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/) 저장소에서 관리합니다. 아래 명령은 해당 저장소를 클론한 위치에서 실행합니다.

```bash
git clone https://github.com/oniops/tfmodule-examples.git
```

### 시나리오 1: 기본 Cross-Region 백업

```bash
cd tfmodule-examples/tfmodule-aws-s3/replica-basic
terraform apply

# 테스트
echo "test" > test.txt
aws s3 cp test.txt s3://$(terraform output -raw source_bucket)/
# 몇 초 후 자동 복제됨
```

### 시나리오 2: KMS 암호화 복제

```bash
cd tfmodule-examples/tfmodule-aws-s3/replica-filtered-kms
terraform apply

# KMS 암호화된 객체만 복제됨
```

### 시나리오 3: 다중 대상 복제

```bash
cd tfmodule-examples/tfmodule-aws-s3/replica-multiple
terraform apply

# 여러 리전/버킷으로 동시 복제
```

### 시나리오 4: Batch Operations 대량 마이그레이션

```bash
cd tfmodule-examples/tfmodule-aws-s3/replica-reporting
terraform apply

# 기존 객체 복제
./create-batch-job.sh

# 상태 모니터링
./check-replication-status.sh
```

## 문제 해결

### 1. 복제가 작동하지 않음

**확인 사항:**
- ✅ 버전 관리 활성화 확인
- ✅ IAM Role 권한 확인
- ✅ 대상 버킷 존재 확인
- ✅ KMS 키 권한 확인 (암호화 사용 시)

```bash
# 복제 설정 확인
aws s3api get-bucket-replication --bucket source-bucket

# IAM Role 정책 확인
aws iam get-role-policy --role-name S3CrrRole --policy-name S3CrrPolicy
```

### 2. Batch Job 실패

**확인 사항:**
- ✅ Manifest 파일 형식
- ✅ IAM Role의 Batch Operations 권한
- ✅ Report 버킷 접근 권한

```bash
# Job 상태 확인
aws s3control describe-job \
  --account-id $ACCOUNT_ID \
  --job-id $JOB_ID

# 오류 리포트 확인
aws s3 cp s3://report-bucket/batch-reports/job-id/results.csv .
cat results.csv
```

### 3. 복제 지연

**CloudWatch 메트릭:**
- `ReplicationLatency`: 복제 지연 시간
- `BytesPendingReplication`: 대기 중인 데이터
- `OperationsPendingReplication`: 대기 중인 작업

### 4. 비용 최적화

**전략:**
- 자주 접근: `STANDARD`
- 간헐적 접근: `STANDARD_IA`
- 아카이브: `GLACIER_IR`, `DEEP_ARCHIVE`
- 필터링으로 불필요한 복제 제외

## FAQ

### Q1: 복제 설정 후 기존 객체도 자동 복제되나요?
**A:** 아니요. 기본적으로 신규 객체만 복제됩니다. 기존 객체는:
- `existing_object_replication = true` 설정, 또는
- Batch Operations 사용

### Q2: 삭제도 복제되나요?
**A:** `delete_marker_replication = true` 설정 시 삭제 마커도 복제됩니다.

### Q3: 복제 중 Storage Class를 변경할 수 있나요?
**A:** 네. `destination.storage_class`에서 지정 가능합니다. 생략하면 원본과 동일합니다.

### Q4: 양방향 복제가 가능한가요?
**A:** 가능하지만 무한 루프 방지를 위해 `source_selection_criteria.replica_modifications = true` 설정이 필요합니다.

### Q5: 복제 상태를 어떻게 확인하나요?
**A:**
```bash
# 개별 객체 상태
aws s3api head-object --bucket bucket --key key --query ReplicationStatus

# 전체 상태 모니터링
./check-replication-status.sh
```

### Q6: Batch Operations와 Replication Rules를 동시에 사용하면 중복 복제되나요?
**A:** 아니요. S3가 ReplicationStatus로 추적하여 중복을 방지합니다.

### Q7: 복제 비용은 얼마나 드나요?
**A:**
- 데이터 전송: GB당 요금
- RTC: 추가 요금
- Batch Operations: Job당 $0.25 + 객체 1000개당 $0.0004

### Q8: S3 Inventory는 언제 사용하나요?
**A:** 수백만 개 이상의 대량 객체를 정기적으로 복제할 때 사용합니다.

## 추가 리소스

- [예제: 기본 복제](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/replica-basic/)
- [예제: KMS 암호화 복제](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/replica-filtered-kms/)
- [예제: 다중 대상 복제](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/replica-multiple/)
- [예제: Batch Operations](https://github.com/oniops/tfmodule-examples/tree/main/tfmodule-aws-s3/replica-reporting/)
- [AWS S3 Replication 공식 문서](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [S3 Batch Operations 가이드](https://docs.aws.amazon.com/AmazonS3/latest/userguide/batch-ops.html)