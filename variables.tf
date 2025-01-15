variable "create" {
  type    = bool
  default = true
}

variable "force_destroy" {
  description = "All objects (including any locked objects) should be deleted from the bucket"
  type        = bool
  default     = false
}

variable "bucket" {
  description = "The fullname of the bucket."
  type        = string
  default     = null
}

variable "bucket_name" {
  description = "The name of the bucket."
  type        = string
  default     = null
}

variable "block_public_acls" {
  description = "block_public_acls"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "block_public_policy"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "ignore_public_acls"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "restrict_public_buckets"
  type        = bool
  default     = true
}

variable "bucket_acl" {
  description = " The canned ACL to apply to the bucket."
  type        = string
  default     = ""
}

variable "object_ownership" {
  description = "Object ownership. Valid values: BucketOwnerPreferred, ObjectWriter or BucketOwnerEnforced"
  type        = string
}

variable "expected_bucket_owner" {
  description = "Account ID of the expected bucket owner."
  type        = string
  default     = null
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = <<EOF
Server-side encryption algorithm to use. Valid values are AES256, aws:kms, and aws:kms:dsse
    AES256        ->  SSE-S3
    aws:kms       ->  SSE-KMS
    aws:kms:dsse  ->  DSSE-KMS
EOF
}

variable "kms_master_key_id" {
  type        = string
  default     = null
  description = <<EOF
AWS KMS master key ID used for the SSE-KMS encryption.
The default `aws/s3` AWS KMS master key is used if this element is absent while the sse_algorithm is aws:kms.
EOF
}

variable "bucket_key_enabled" {
  description = "Whether or not to use Amazon S3 Bucket Keys for SSE-KMS."
  type        = bool
  default     = null
}

variable "s3_logs_bucket" {
  description = "The ID of the bucket where you want Amazon S3 to store server access logs."
  type        = string
  default     = ""
}

variable "s3_logs_prefix" {
  description = "The ID of the bucket where you want Amazon S3 to store server access logs."
  type        = string
  default     = null
}

variable "object_lock_enabled" {
  description = "Indicates whether this bucket has an Object Lock configuration enabled."
  type        = bool
  default     = false
}

variable "object_lock_mode" {
  description = "Default Object Lock retention mode you want to apply to new objects placed in the specified bucket. Valid values: COMPLIANCE, GOVERNANCE"
  type        = string
  default     = "COMPLIANCE"
}

variable "object_lock_days" {
  description = "Number of days that you want to specify for the default retention period."
  type        = number
  default     = 365
}

variable "enable_bucket_lifecycle" {
  type    = bool
  default = false
}

variable "lifecycle_rules" {
  type        = any
  default     = null
  description = <<EOF

  lifecycle_rules = [
    {
      id                = "default-rule"
      status            = "Enabled"
      expiration_days   = 730
    },
  ]

  lifecycle_rules = [
    {
      id                = "first-rule"
      status            = "Enabled"
      glacier_days      = 180
      deep_archive_days = 365
      expiration_days   = 730
      filter          = {
        prefix = "first/"
      }
    },
    {
      id                = "seconds-rule"
      status            = "Enabled"
      itl_tier_days     = 90
      glacier_days      = 180
      deep_archive_days = 365
      expiration_days   = 730
      filter          = {
        prefix = "second/"
      }
    }
  ]

  ----- filters example -----
  # filter
    - base on object's prefix
      filter = {
        prefix = "logs"
      }

    - base on object's tag
      filter = {
        tag    = {
          Project = "simple"
        }
      }

    - base on object's prefix and one more tags
      filter = {
        and = [
          {
            prefix = "multi"
            tags   = {
              Porject     = "simple"
              ProductType = "EC2"
            }
          }
        ]
      }

    # base on object's prefix
    filter = {
      prefix = "logs"
      object_size_greater_than = 500    # (Optional) Minimum object size (in bytes) to which the rule applies.
      object_size_less_than = 50        # (Optional) Maximum object size (in bytes) to which the rule applies.
    }

    # rendering sample
    filter {
      and {
        prefix = "logs/"
        tags = {
          rule      = "Expire old CloudFront logs"
          "ops:AutoClean" = "true"
        }
      }
    }

  ----- versioning example -----
  # must be enabled versioning first
  lifecycle_rules = [
    {
      id                                   = "default-rule"
      status                               = "Enabled"
      deep_archive_days                    = 180
      expiration_days                      = 730
      noncurrent_version_deep_archive_days = 90
      noncurrent_version_expiration_days   = 730
    }
  ]

EOF
}

variable "enable_versioning" {
  type    = bool
  default = false
}

variable "versioning" {
  type        = map(string)
  default     = {}
  description = <<EOF
Enable versioning state of the bucket

  versioning = {
    status                = "Enabled"  # Valid values: Enabled, Suspended, or Disabled
    mfa_delete            = "Disabled" # Valid values: Enabled or Disabled
    expected_bucket_owner = null # Account ID of the expected bucket owner.
  }

EOF
}

# replication
variable "enable_replication" {
  type    = bool
  default = false
}

variable "bucket_versioning_status" {
  type    = string
  default = ""
  description = <<EOF
  bucket_versioning_status = try(aws_s3_bucket_versioning.this.versioning_configuration.*.status[0], null)
EOF
}

variable "replication_role_arn" {
  description = "ARN of the IAM role for Amazon S3 to assume when replicating the objects."
  type        = string
  default     = null
}

variable "replication_rules" {
  type        = any
  default     = null
  description = <<EOF
Configuration for S3 bucket replication.

      id                          = "all"
      status                      = true
      priority                    = 0
  replication_rules = [
    {
      id                          = "all"
      status                      = true
      delete_marker_replication   = true                          # delete_marker_replication attribute is mandatory because of using filter.
      # Can't set following "existing_object_replication" attribute because AWS is not supported yet.
      # if set true, You have to add IAM polices for S3 BatchOperation
      # existing_object_replication = true
      destination                 = {
        bucket             = module.s3_example_clone.bucket_arn   # ARN of the bucket where you want Amazon S3 to store the results.
        storage_class      = "STANDARD_IA"                        # see - https://docs.aws.amazon.com/AmazonS3/latest/API/API_Destination.html#AmazonS3-Type-Destination-StorageClass
        replica_kms_key_id = data.aws_kms_key.replica.arn         # if set this value, You have to configure `source_selection_criteria.sse_kms_encrypted_objects`
      }

      source_selection_criteria = {
        sse_kms_encrypted_objects = {
          enabled = true
        }
      }

    }
  ]

  ----- filters example -----
  # filter
    - base on object's prefix
      filter = {
        prefix = "oss"
      }

    - base on object's tag
      filter = {
        tag    = {
          Project = "simple"
        }
      }

    - base on object's prefix and one more tags
      filter = {
        and = [
          {
            prefix = "multi"
            tags   = {
              Porject     = "simple"
              Team        = "DevOps"
              ProductType = "EC2"
            }
          }
        ]
      }
EOF

}

variable "replication_report_bucket_arn" {
  description = "For S3 Batch Operations, Report bucket arn must be defined."
  type        = string
  default     = null
}

################################################################################
# S3 bucket policies
################################################################################
variable "attach_deny_insecure_transport_policy" {
  type = bool
  default = false
}

variable "attach_lb_log_delivery_policy" {
  description = "Controls if S3 bucket should have ALB/NLB log delivery policy attached"
  type        = bool
  default     = false
}

variable "attach_deny_incorrect_encryption_headers" {
  description = "Controls if S3 bucket should deny incorrect encryption headers policy attached."
  type        = bool
  default     = false
}

variable "attach_access_log_delivery_policy" {
  description = "Controls if S3 bucket should have S3 access log delivery policy attached"
  type        = bool
  default     = false
}

variable "attach_elb_log_delivery_policy" {
  description = "Controls if S3 bucket should have ELB log delivery policy attached"
  type        = bool
  default     = false
}

variable "access_log_delivery_policy_source_buckets" {
  type        = list(string)
  default     = []
  description = <<EOF
List of S3 bucket ARNs which should be allowed to deliver access logs to this bucket.

  access_log_delivery_policy_source_buckets = [
    "arn:aws:s3:::your-source-bucket-0001-s3",
    "arn:aws:s3:::your-source-bucket-0001-s2"
  ]
EOF
}

variable "access_log_delivery_policy_source_accounts" {
  type        = list(string)
  default     = []
  description = <<EOF
List of AWS Account IDs should be allowed to deliver access logs to this bucket.

  access_log_delivery_policy_source_buckets = [
    "111122223333",
    "444455556666"
  ]
EOF
}


variable "attach_custom_policy" {
  type = string
  default = null
  description = <<EOF
A valid bucket policy JSON document.

  attach_custom_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        "Sid" : "AllowCloudFrontDistributeForWhiteLabel",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudfront.amazonaws.com"
        },
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::dev-an2d-platform-wl-brandsite-s3/*",
        "Condition" : {
          "ArnLike" : {
            "aws:SourceArn" : "arn:aws:cloudfront::370166107047:distribution/*"
          }
        }
      }
    ]
  })

  or

  data "aws_iam_policy_document" "custom" { ... }

  attach_custom_policy = data.aws_iam_policy_document.custom.json

EOF
}
variable "custom_policy" {
  type        = string
  default     = null
  description = <<EOF
A valid bucket policy JSON document.

  data "aws_iam_policy_document" "custom" { ... }

  custom_policy = data.aws_iam_policy_document.custom.json

EOF
}

variable "source_vpce" {
  type = string
  default = ""
}