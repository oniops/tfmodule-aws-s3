variable "s3_logs_bucket" {
  description = "The ID of the bucket where you want Amazon S3 to store server access logs."
  type        = string
  default     = ""
}

variable "s3_logs_prefix" {
  description = "The prefix for all log object keys. Defaults to `logs/{bucket_name}/`."
  type        = string
  default     = null
}
