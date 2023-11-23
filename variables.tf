variable "create_bucket" {
  type = bool
  default = true
}

variable "bucket" {
  description = "The name of the bucket."
  type        = string
  default = null
}

variable "bucket_alias" {
  description = "The name of the bucket."
  type        = string
  default = null
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
