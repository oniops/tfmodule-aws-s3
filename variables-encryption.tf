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
