################################################################################
# S3 bucket policies
################################################################################
variable "attach_deny_insecure_transport_policy" {
  type    = bool
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

variable "attach_aws_inspector_report_policy" {
  description = "Controls if S3 bucket should have AWS Inspector Report policy attached"
  type        = bool
  default     = false
}

variable "access_log_delivery_policy_source_buckets" {
  type        = set(string)
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
  type        = set(string)
  default     = []
  description = <<-EOF
List of AWS Account IDs should be allowed to deliver access logs to this bucket.

  access_log_delivery_policy_source_buckets = [
    "111122223333",
    "444455556666"
  ]
EOF
}

variable "cloudfront_distributions_arn" {
  type        = set(string)
  default     = []
  description = <<-EOF
List of AWS Cloudfront OAC(Origin Access Control) IDs should be allowed to access this bucket.

  cloudfront_distributions_arn = [
    "arn:aws:cloudfront::111122223333:distribution/A1B3CD6EFGBWM"
  ]
EOF
}

variable "source_vpce" {
  description = "Source VPC endpoint for accessing S3 bucket."
  type        = string
  default     = null
}

variable "attach_custom_policy" {
  type        = any
  default     = null
  description = <<EOF
Custom bucket policy statements. Accepts any of:
  - a list of statement objects (recommended, native HCL)
  - a single statement object
  - a JSON document string (backwards compatible)

Native HCL example (recommended):

  attach_custom_policy = [
    {
      Sid       = "AllowCloudFrontDistributeForWhiteLabel"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::demo-an2d-example1022-s3/*"
      Condition = {
        ArnLike = {
          "aws:SourceArn" = "arn:aws:cloudfront::111122223333:distribution/*"
        }
      }
    }
  ]

EOF
}
