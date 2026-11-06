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

variable "bucket_versioning_status" {
  type        = string
  default     = ""
  description = <<EOF
  bucket_versioning_status = try(aws_s3_bucket_versioning.this.versioning_configuration.*.status[0], null)
EOF
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
