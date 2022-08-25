variable "bucket" {
  description = "The name of the bucket."
  type        = string
}

variable "block_public_acls" {
  description = "block_public_acls"
  type        = bool
  default = true
}

variable "block_public_policy" {
  description = "block_public_policy"
  type        = bool
  default = true
}

variable "ignore_public_acls" {
  description = "ignore_public_acls"
  type        = bool
  default = true
}

variable "restrict_public_buckets" {
  description = "restrict_public_buckets"
  type        = bool
  default = true
}

variable "bucket_acl" {
  description = " The canned ACL to apply to the bucket."
  type        = string
  default = ""
}

variable "object_ownership" {
  description = "Object ownership. Valid values: BucketOwnerPreferred, ObjectWriter or BucketOwnerEnforced"
  type        = string
}
