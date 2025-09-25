# S3 Batch Operations Replication 예제

이 예제는 S3 Batch Operations를 사용한 복제 구성과 리포트 버킷 설정을 보여줍니다.
특히 `replication_report_bucket_arn` 설정과 자동 생성된 IAM Role 사용법을 설명합니다.

## 특징

- **KMS 암호화**: 소스 버킷에 KMS 키를 사용한 서버 측 암호화 적용
- **Cross-Region 복제**: 다른 리전으로 버킷 복제
- **복제 메트릭**: 15분 RTC(Replication Time Control) 설정
- **복제 보고서**: S3 Batch Operations를 위한 보고서 버킷
- **라이프사이클 관리**: 365일 후 객체 자동 삭제

## 구성 요소

1. **소스 버킷** (`ex03-replica-source`):
   - KMS 암호화 활성화
   - 버전 관리 활성화 (복제 필수)
   - 라이프사이클 규칙 적용
   - 복제 설정 포함

2. **대상 버킷** (`ex03-replica-target`):
   - 다른 리전에 위치 (provider: aws.replica)
   - 버전 관리 활성화

3. **보고서 버킷** (`ex03-replica-report`):
   - S3 Batch Operations 보고서 저장용

## S3 Batch Operations 테스트 방법

### 1. 인프라 배포
```bash
terraform init
terraform apply
```

### 2. 테스트 파일 업로드
```bash
# Source 버킷에 테스트 파일 생성
echo "Test content 1" > test1.txt
echo "Test content 2" > test2.txt
mkdir -p folder
echo "Test content 3" > folder/test3.txt

# 파일 업로드
aws s3 cp test1.txt s3://$(terraform output -raw source_bucket)/
aws s3 cp test2.txt s3://$(terraform output -raw source_bucket)/
aws s3 cp folder/test3.txt s3://$(terraform output -raw source_bucket)/folder/
```

### 3. Batch Operations Job 실행

#### 방법 1: 제공된 스크립트 사용 (권장)
```bash
./create-batch-job.sh
```

#### 방법 2: 수동 실행
```bash
# Terraform output에서 Role ARN 확인
terraform output replication_role_arn

# batch-job.json 파일에서 RoleArn 필드에 위 ARN 입력
# 그 후 AWS CLI로 job 생성
aws s3control create-job --cli-input-json file://batch-job.json
```

### 4. Job 상태 모니터링
```bash
# Job ID는 create-batch-job.sh 실행 결과에서 확인
JOB_ID="your-job-id"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Job 상태 확인
aws s3control describe-job \
  --account-id $ACCOUNT_ID \
  --job-id $JOB_ID \
  --region ap-northeast-2
```

### 5. 리포트 확인
```bash
# Report 버킷의 결과 확인
aws s3 ls s3://$(terraform output -raw report_bucket)/batch-reports/ --recursive

# 리포트 다운로드
aws s3 cp s3://$(terraform output -raw report_bucket)/batch-reports/ ./reports --recursive
```

## batch-job.json 상세 설명

### 주요 필드 설명

- **AccountId**: AWS 계정 ID
- **ConfirmationRequired**: Job 실행 전 확인 필요 여부 (false면 자동 실행)
- **Operation.S3ReplicateObject**:
  - `TargetResource`: 대상 버킷 ARN
  - `StorageClass`: 대상 객체의 스토리지 클래스 (STANDARD, STANDARD_IA, GLACIER 등)
  - `CannedAccessControlList`: ACL 설정 (private, public-read 등)
- **Manifest**: 복제할 객체 목록
  - `Format`: CSV 형식 지정
  - `Fields`: CSV 컬럼 정의 (Bucket, Key)
  - `Location`: 매니페스트 파일 위치와 ETag
- **Priority**: Job 우선순위 (1-2147483647, 높을수록 우선)
- **RoleArn**: tfmodule-aws-s3에서 자동 생성된 IAM Role ARN
- **Report**: 실행 결과 리포트
  - `Bucket`: 리포트 저장 버킷
  - `ReportScope`: AllTasks(모든 작업) 또는 FailedTasksOnly(실패만)

### IAM Role 사용

tfmodule-aws-s3는 replication 설정 시 자동으로 IAM Role을 생성합니다:
- Role 이름: `${project}${bucket_name}S3CrrRole`
- 필요한 모든 권한 자동 포함
- Terraform output으로 ARN 확인 가능: `terraform output replication_role_arn`

## 주의사항

- 복제를 사용하려면 반드시 버전 관리가 활성화되어야 합니다
- `replication_report_bucket_arn`은 Batch Operations 사용 시 필수
- 자동 생성된 IAM Role에는 Report 버킷 접근 권한도 포함됩니다
- force_destroy는 테스트 환경에서만 사용하세요