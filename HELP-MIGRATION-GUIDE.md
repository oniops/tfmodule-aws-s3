# v1.7.0 → v1.8.0 마이그레이션 가이드

[← README 로 돌아가기](./README.md)

v1.8.0 은 `lifecycle_rules` 와 `replication_rules` 입력 형식이 바뀐 **호환되지 않는(Breaking) 릴리스**입니다. 두 변수를 쓰지 않는 모듈 호출은 `ref` 와 Terraform 버전만 올리면 됩니다.

## 변경 요약

| 항목 | v1.7.0 | v1.8.0 | 조치 |
|------|--------|--------|------|
| Terraform | `>= 1.5.7` | `>= 1.7.0` | Terraform 업그레이드 (`removed` 블록 사용) |
| AWS Provider | `>= 6.0.0` | `>= 6.0.0, < 7.0.0` | 7.x 사용 중이면 6.x 로 고정 |
| `lifecycle_rules` | `any` (list) | `map(object)`, key = rule ID | **입력 변환 필요** |
| `replication_rules` | `any` (list) | `map(object)`, key = rule ID | **입력 변환 필요** |
| 복제 IAM 정책 연결 | `aws_iam_policy_attachment` | `aws_iam_role_policy_attachment` | 자동 처리 (state 이동만, 분리 없음) |
| `cloudfront_distributions_arn`, `access_log_delivery_policy_source_*` | `list(string)` | `set(string)` | 없음 (list 그대로 전달 가능) |

## 1단계: 버전 올리기

```hcl
module "my_bucket" {
  source = "git::https://github.com/oniops/tfmodule-aws-s3.git?ref=v1.8.0"
  # ...
}
```

```bash
terraform version          # 1.7.0 이상인지 확인
terraform init -upgrade
```

## 2단계: `lifecycle_rules` 변환

| v1.7.0 | v1.8.0 |
|--------|--------|
| `[ { id = "rule-a", ... } ]` | `{ "rule-a" = { ... } }` |
| `id` 생략 (기본 ID `five-years-rule`) | map key 를 `"five-years-rule"` 로 지정해야 기존 규칙과 같은 ID 유지 |
| `status = "Enabled"` / `"Disabled"` | `enabled = true` / `false` (기본값 `true`) |
| `standard_ia_days`, `intelligent_tiering_days`, `onezone_ia_days`, `glacier_ir_days`, `glacier_days`, `deep_archive_days` | `transitions = { STANDARD_IA = 30, GLACIER = 180, ... }` |
| `noncurrent_version_glacier_days`, `noncurrent_version_deep_archive_days` | `noncurrent_version_transitions = { GLACIER = 30, DEEP_ARCHIVE = 90 }` |
| `noncurrent_version_expiration_days` | 동일 (v1.7.0 에서는 렌더링되지 않던 버그가 수정됨) |
| `filter.tag = { Project = "demo" }` | `filter.tag = { key = "Project", value = "demo" }` (태그 2개 이상이면 `filter.and.tags`) |
| `filter.and = [ { prefix, tags } ]` (list) | `filter.and = { prefix, tags }` (object) |
| `xxx_days = 0` (전환 생략) | 해당 key 를 넣지 않음 (`0` 을 넣으면 0일 전환으로 렌더링됨) |

**v1.7.0**

```hcl
enable_bucket_lifecycle = true
lifecycle_rules = [
  {
    id                                 = "archive-old-data"
    status                             = "Enabled"
    standard_ia_days                   = 30
    glacier_days                       = 180
    deep_archive_days                  = 365
    expiration_days                    = 730
    noncurrent_version_glacier_days    = 30
    noncurrent_version_expiration_days = 365 # v1.7.0 에서는 적용되지 않았음
    filter = {
      and = [
        {
          prefix = "logs/"
          tags   = { Archive = "true" }
        }
      ]
    }
  },
  {
    id              = "tmp-cleanup"
    status          = "Disabled"
    expiration_days = 7
    filter = {
      tag = { Temp = "true" }
    }
  },
]
```

**v1.8.0**

```hcl
enable_bucket_lifecycle = true
lifecycle_rules = {
  "archive-old-data" = {
    filter = {
      and = {
        prefix = "logs/"
        tags   = { Archive = "true" }
      }
    }
    transitions = {
      STANDARD_IA  = 30
      GLACIER      = 180
      DEEP_ARCHIVE = 365
    }
    expiration_days                    = 730
    noncurrent_version_transitions     = { GLACIER = 30 }
    noncurrent_version_expiration_days = 365
  }

  "tmp-cleanup" = {
    enabled         = false
    expiration_days = 7
    filter = {
      tag = { key = "Temp", value = "true" }
    }
  }
}
```

## 3단계: `replication_rules` 변환

| v1.7.0 | v1.8.0 |
|--------|--------|
| `[ { id = "rule-a", ... } ]` | `{ "rule-a" = { ... } }` |
| `priority` (선택) | `priority` **필수**, 규칙마다 고유 |
| `status = true` / `false` (생략 시 **Disabled**) | `enabled = true` / `false` (생략 시 **Enabled**) — 비활성 규칙은 `enabled = false` 를 명시 |
| `existing_object_replication = false` (Disabled 블록 렌더링) | `false` 이면 블록 자체를 생략 |
| `filter.tag = { Project = "demo" }` | `filter.tag = { key = "Project", value = "demo" }` |
| `filter.and = [ { prefix, tags } ]` | `filter.and = { prefix, tags }` |
| `destination.account` 또는 `destination.account_id` | `destination.account_id` |
| `destination.access_control_translation = { owner = "Destination" }` | `destination.owner_override = true` (`account_id` 필요) |
| `destination.encryption_configuration.replica_kms_key_id` 또는 `destination.replica_kms_key_id` | `destination.replica_kms_key_id` |
| `destination.replication_time = { status = "Enabled", minutes = 15 }` | `destination.replication_time = true` (`metrics = true` 필요) |
| `destination.metrics = { status = "Enabled", minutes = 15 }` | `destination.metrics = true` (임계값 15분 고정) |
| `source_selection_criteria.sse_kms_encrypted_objects = { enabled = true }` (또는 `status = "Enabled"`) | `source_selection_criteria.sse_kms_encrypted_objects = true` |
| `source_selection_criteria.replica_modifications = { enabled = true }` | `source_selection_criteria.replica_modifications = true` |

**v1.7.0**

```hcl
enable_versioning  = true
enable_replication = true
replication_rules = [
  {
    id                        = "dr-replication"
    status                    = true
    priority                  = 0
    delete_marker_replication = false
    filter = {
      prefix = "data/"
    }
    destination = {
      bucket        = "arn:aws:s3:::demo-an2p-target-s3"
      storage_class = "STANDARD_IA"
      account       = "444455556666"
      access_control_translation = {
        owner = "Destination"
      }
      encryption_configuration = {
        replica_kms_key_id = "arn:aws:kms:us-west-2:444455556666:key/mock"
      }
      replication_time = { status = "Enabled", minutes = 15 }
      metrics          = { status = "Enabled", minutes = 15 }
    }
    source_selection_criteria = {
      sse_kms_encrypted_objects = { enabled = true }
    }
  },
]
```

**v1.8.0**

```hcl
enable_versioning  = true
enable_replication = true
replication_rules = {
  "dr-replication" = {
    priority                  = 0
    delete_marker_replication = false
    filter = {
      prefix = "data/"
    }
    destination = {
      bucket             = "arn:aws:s3:::demo-an2p-target-s3"
      storage_class      = "STANDARD_IA"
      account_id         = "444455556666"
      owner_override     = true
      replica_kms_key_id = "arn:aws:kms:us-west-2:444455556666:key/mock"
      replication_time   = true
      metrics            = true
    }
    source_selection_criteria = {
      sse_kms_encrypted_objects = true
    }
  }
}
```

> v1.7.0 README 예제처럼 `replication_time` 을 `destination` 밖(규칙 최상위)에 두었다면 v1.7.0 에서는 **무시되어 RTC 가 적용되지 않았습니다.** v1.8.0 에서 `destination.replication_time = true` 로 옮기면 RTC 가 새로 켜지고 추가 요금이 발생하므로, 의도한 경우에만 설정하세요.

## 4단계: 복제 IAM 정책 연결 (자동 처리)

모듈이 직접 만든 복제 Role(`replication_role_arn` 미지정)을 쓰는 경우, v1.8.0 은 `aws_iam_policy_attachment` 를 `aws_iam_role_policy_attachment` 로 교체합니다. 모듈 안의 `removed` 블록(`destroy = false`)이 기존 리소스를 **분리(detach)하지 않고 state 에서만 제거**하고, 새 리소스가 같은 정책을 다시 연결합니다. 별도의 `terraform state mv` 는 필요 없습니다.

```
# module.source.aws_iam_policy_attachment.replica[0] will no longer be managed by Terraform
# module.source.aws_iam_role_policy_attachment.replica[0] will be created
```

`replication_report_bucket_arn` 을 지정했다면 복제 정책에 Batch Operations manifest 읽기 권한(`AllowGetManifestFromReportBucket`)이 추가되어 `aws_iam_policy.replica` 가 in-place 로 변경됩니다.

## 5단계: plan 검증

```bash
terraform init -upgrade
terraform validate
terraform plan
```

plan 결과가 다음 범위 안에 있는지 확인하세요.

| 리소스 | 예상 변경 |
|--------|-----------|
| `aws_s3_bucket.this` | **변경 없음** — replace/destroy 가 보이면 apply 하지 말고 입력을 다시 확인 |
| `aws_s3_bucket_lifecycle_configuration.this` | in-place 업데이트 가능 (규칙 순서가 rule ID 순으로 정렬됨, `noncurrent_version_expiration` 추가 등) |
| `aws_s3_bucket_replication_configuration.this` | in-place 업데이트 가능 (규칙 순서 정렬, `existing_object_replication` Disabled 블록 제거 등) |
| `aws_iam_policy_attachment.replica` → `aws_iam_role_policy_attachment.replica` | state 에서 제거 + 생성 (4단계) |

> ⚠️ `lifecycle_rules` / `replication_rules` 에 v1.7.0 속성(`id`, `status`, `glacier_days`, `account`, `access_control_translation` 등)을 그대로 남겨 두면 **오류 없이 무시**됩니다. 예를 들어 `glacier_days = 180` 을 `transitions` 로 옮기지 않으면 plan 에서 해당 전환이 **삭제**로 표시됩니다. plan 에서 `transition`, `expiration`, `encryption_configuration`, `replication_time` 블록이 사라지는지 반드시 확인하세요.
