# AWS S3 Terraform Module Requirements

## Overview
This project is a Terraform module for creating and managing AWS S3 buckets. It provides a standardized way to provision S3 buckets in enterprise environments with support for various security, lifecycle, and replication features.

## Core Requirements

### 1. Basic S3 Bucket Management
- **Bucket Creation and Naming Convention**
  - Context-based naming convention support (`{prefix}-{bucket_name}-s3`)
  - Custom bucket name or auto-generation option
  - Force destroy option support

- **Public Access Blocking**
  - All public access blocking settings enabled by default
  - Individual setting control (block_public_acls, block_public_policy, etc.)

- **Ownership Control**
  - Object Ownership settings (BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced)
  - ACL management support (except BucketOwnerEnforced)

### 2. Security Features

#### Encryption
- **Server-side Encryption Support**
  - SSE-S3 (AES256)
  - SSE-KMS (aws:kms)
  - DSSE-KMS (aws:kms:dsse)
- **KMS Key Management**
  - Custom KMS key or default aws/s3 key usage
  - S3 Bucket Key enable option

#### Bucket Policies
- **Automatic Security Policy Application**
  - Force HTTPS transport (deny_insecure_transport)
  - Block incorrect encryption headers
  - VPC endpoint access restriction
  - CloudFront OAC access permission

- **Service-specific Access Policies**
  - ALB/NLB log delivery policy
  - ELB log delivery policy
  - S3 access log delivery policy
  - AWS Inspector report export policy

- **Custom Policy Support**
  - Direct application of user-defined bucket policy JSON

### 3. Data Management Features

#### Version Control
- **Version control enable/disable**
- **MFA delete protection option**
- **Version status management (Enabled, Suspended, Disabled)**

#### Lifecycle Management
- **Storage Class Transition Support**
  - STANDARD_IA (Infrequent Access)
  - INTELLIGENT_TIERING
  - ONEZONE_IA
  - GLACIER_IR (Instant Retrieval)
  - GLACIER (Flexible Retrieval)
  - DEEP_ARCHIVE

- **Object Expiration Settings**
  - Day-based expiration period
  - Non-current version expiration

- **Filtering Rules**
  - Prefix-based filter
  - Tag-based filter
  - Object size-based filter (greater_than, less_than)
  - Composite filter (AND condition)

- **Transition Minimum Object Size Settings**
  - all_storage_classes_128K (default)
  - varies_by_storage_class

#### Object Lock
- **Compliance Mode**
  - COMPLIANCE or GOVERNANCE mode selection
  - Default retention period setting (in days)

### 4. Replication Features

#### Cross-Region/Cross-Account Replication
- **Replication Rule Configuration**
  - Priority-based rule management
  - Delete marker replication
  - Existing object replication (requires S3 Batch Operations)

- **Replication Destination Configuration**
  - Target bucket and storage class specification
  - KMS encrypted object replication support
  - Replication Time Control (RTC)
  - Replication metrics configuration

- **Replication Filters**
  - Prefix, tag-based filtering
  - Composite filter support

- **IAM Role**
  - Automatic IAM role creation or use existing role
  - Automatic permission configuration

### 5. Logging and Monitoring

#### S3 Access Logging
- **Log destination bucket specification**
- **Log prefix customization**
- **Automatic log path generation** (`logs/{bucket_name}/`)

### 6. Context Management
- **Project Metadata**
  - project, region, account_id
  - Environment information
  - Team and domain information
  - Automatic tag application

### 7. Module Outputs
- **Bucket Information**
  - bucket_name (full name)
  - bucket_simple_name (simple name)
  - bucket_id, bucket_arn
  - bucket_domain_name
  - bucket_regional_domain_name

- **Status Information**
  - versioning_status
  - enable_versioning_status
  - bucket_policy (applied policy JSON)

## Usage Examples

### Basic Bucket Creation
```hcl
module "basic_s3" {
  source            = "git::https://github.com/your-org/tfmodule-aws-s3.git"
  context           = var.context
  bucket_name       = "my-bucket"
  object_ownership  = "ObjectWriter"
  enable_versioning = true
}
```

### Encryption and Lifecycle Configuration
```hcl
module "encrypted_s3" {
  source                  = "git::https://github.com/your-org/tfmodule-aws-s3.git"
  context                 = var.context
  bucket_name             = "encrypted-bucket"
  object_ownership        = "BucketOwnerEnforced"
  sse_algorithm           = "aws:kms"
  kms_master_key_id       = aws_kms_key.s3.id
  enable_bucket_lifecycle = true
  lifecycle_rules = [
    {
      id                = "archive-old-data"
      status            = "Enabled"
      glacier_ir_days   = 90
      deep_archive_days = 365
      expiration_days   = 730
    }
  ]
}
```

### Cross-Region Replication Configuration
```hcl
module "replicated_s3" {
  source               = "git::https://github.com/your-org/tfmodule-aws-s3.git"
  context              = var.context
  bucket_name          = "source-bucket"
  enable_versioning    = true
  enable_replication   = true
  replication_rules = [
    {
      id                        = "replicate-all"
      status                    = true
      delete_marker_replication = true
      destination = {
        bucket        = "arn:aws:s3:::destination-bucket"
        storage_class = "GLACIER_IR"
      }
    }
  ]
}
```

## Constraints and Considerations

1. **Version Control**: Version control must be enabled to use replication features
2. **Object Lock**: Can only be set during bucket creation, cannot be changed afterwards
3. **Replication Settings**: Existing object replication requires S3 Batch Operations permissions
4. **Lifecycle Filters**: When setting filters, at least one of prefix, tag, object_size_greater_than, object_size_less_than is required
5. **Policy Application Order**: Applied in order of S3 bucket → Public access block → Bucket policy to prevent conflicts