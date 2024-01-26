variable "create_bucket" {
  type    = bool
  default = true
}

variable "bucket" {
  description = "The name of the bucket."
  type        = string
  default     = null
}

variable "bucket_alias" {
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

variable "sse_algorithm" {
  description = "Server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
  type        = string
  default     = "AES256"
}

variable "s3_logs_bucket" {
  description = "The ID of the bucket where you want Amazon S3 to store server access logs."
  type        = string
  default     = ""
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
      id                = "two-years-rule"
      status            = "Enabled"
      glacier_days      = 180
      deep_archive_days = 365
      expiration_days   = 730
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

  replication_rules = [
      {
        id     = "all"
        priority     = 0
        status = "Enabled"
        delete_marker_replication = true
        destination = {
          bucket        = "$${destination_bucket_arn}" # ARN of the bucket where you want Amazon S3 to store the results.
          storage_class = "STANDARD"
        }
      },
  ]

  ----- attributes example -----
  filter
  - base on object's prefix
    filter = {
      prefix = "one"
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