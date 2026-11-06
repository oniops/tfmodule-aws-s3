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
  description = <<EOF
S3 replication rules. The map key is the rule ID. Bucket versioning must be enabled.

  replication_rules = {
    "first-rule" = {
      priority    = 0                               # required, unique per rule
      filter      = { prefix = "first/" }
      destination = { bucket = module.target_first.bucket_arn }
    }

    "second-rule" = {
      priority                    = 10
      enabled                     = true            # default: true
      delete_marker_replication   = true            # default: false
      existing_object_replication = false           # default: false (requires AWS support enablement)
      filter                      = { prefix = "second/" }
      destination = {
        bucket             = module.target_second.bucket_arn
        storage_class      = "GLACIER_IR"           # default: same as source
        account_id         = "444455556666"         # cross-account replication
        owner_override     = true                   # replica owner = destination account (requires account_id)
        replica_kms_key_id = data.aws_kms_key.replica.arn
        replication_time   = true                   # S3 RTC 15 minutes (requires metrics = true)
        metrics            = true
      }
      source_selection_criteria = {
        sse_kms_encrypted_objects = true            # required when replica_kms_key_id is set
        replica_modifications     = false
      }
    }
  }

  filter (all optional, mirrors the AWS replication filter schema)
    prefix = "logs/"
    tag    = { key = "Project", value = "demo" }
    and = {                                         # cannot be combined with prefix/tag above
      prefix = "logs/"
      tags   = { Project = "demo", Team = "DevOps" }
    }
EOF

  type = map(object({
    priority                    = number
    enabled                     = optional(bool, true)
    delete_marker_replication   = optional(bool, false)
    existing_object_replication = optional(bool, false)

    filter = optional(object({
      prefix = optional(string)
      tag    = optional(object({ key = string, value = string }))
      and = optional(object({
        prefix = optional(string)
        tags   = optional(map(string))
      }))
    }), {})

    destination = object({
      bucket             = string
      storage_class      = optional(string)
      account_id         = optional(string)
      owner_override     = optional(bool, false)
      replica_kms_key_id = optional(string)
      replication_time   = optional(bool, false)
      metrics            = optional(bool, false)
    })

    source_selection_criteria = optional(object({
      sse_kms_encrypted_objects = optional(bool, false)
      replica_modifications     = optional(bool, false)
    }), {})
  }))
  default = {}

  validation {
    condition     = length(distinct([for rule in values(var.replication_rules) : rule.priority])) == length(var.replication_rules)
    error_message = "replication_rules priority must be unique per rule."
  }

  validation {
    condition = alltrue([
      for rule in values(var.replication_rules) :
      rule.filter.and == null || (rule.filter.prefix == null && rule.filter.tag == null)
    ])
    error_message = "replication_rules filter.and cannot be combined with filter.prefix or filter.tag. Put every condition inside filter.and."
  }

  validation {
    condition = alltrue([
      for rule in values(var.replication_rules) :
      rule.destination.replica_kms_key_id == null || rule.source_selection_criteria.sse_kms_encrypted_objects
    ])
    error_message = "replication_rules destination.replica_kms_key_id requires source_selection_criteria.sse_kms_encrypted_objects = true."
  }

  validation {
    condition = alltrue([
      for rule in values(var.replication_rules) :
      !rule.destination.replication_time || rule.destination.metrics
    ])
    error_message = "replication_rules destination.replication_time (S3 RTC) requires destination.metrics = true."
  }

  validation {
    condition = alltrue([
      for rule in values(var.replication_rules) :
      !rule.destination.owner_override || rule.destination.account_id != null
    ])
    error_message = "replication_rules destination.owner_override requires destination.account_id."
  }
}

variable "replication_report_bucket_arn" {
  description = "For S3 Batch Operations, Report bucket arn must be defined."
  type        = string
  default     = null
}
