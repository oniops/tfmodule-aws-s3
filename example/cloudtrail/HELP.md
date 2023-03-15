# cloudtrail

```
terraform init
terraform plan
terraform apply
```

```
aws s3api put-bucket-versioning \
  --bucket otcmp-tbd-cloudtrail-s3 \
  --versioning-configuration MFADelete=Enabled \
  --mfa "MFA_SERIAL_ROOT TOKEN" 
```


