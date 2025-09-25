# S3 Bucket Replication with Report Example

이 예제는 AWS S3 버킷 간 복제를 설정하는 방법을 보여줍니다.
복제 보고서 버킷을 포함하여 복제 상태를 모니터링할 수 있습니다.

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

## 사용 방법

```bash
# 초기화
terraform init

# 실행 계획 확인
terraform plan

# 리소스 생성
terraform apply

# 리소스 삭제
terraform destroy
```

## 주의사항

- 복제를 사용하려면 반드시 버전 관리가 활성화되어야 합니다
- KMS 암호화된 객체를 복제하려면 적절한 IAM 권한이 필요합니다
- 대상 리전에도 KMS 키가 있어야 합니다
- force_destroy는 테스트 환경에서만 사용하세요