variable "enable_bucket_lifecycle" {
  type    = bool
  default = false
}

variable "lifecycle_rules" {
  description = <<EOF
S3 lifecycle rules. The map key is the rule ID.

  lifecycle_rules = {
    "reports-7d" = {
      filter          = { prefix = "reports/" }
      expiration_days = 7
    }

    "logs-archive" = {
      enabled = true                      # default: true
      filter = {
        and = {                           # use `and` to combine two or more conditions
          prefix = "logs/"
          tags   = { Project = "demo", ProductType = "EC2" }
        }
      }
      transitions = {                     # STORAGE_CLASS = days
        GLACIER_IR   = 90
        DEEP_ARCHIVE = 365
      }
      expiration_days                    = 730
      noncurrent_version_transitions     = { GLACIER = 30 }   # STORAGE_CLASS = noncurrent days
      noncurrent_version_expiration_days = 365
    }

    "all-objects" = {                     # no filter = every object in the bucket
      expiration_days = 1825
    }
  }

  filter (all optional, mirrors the AWS lifecycle filter schema)
    prefix                   = "logs/"
    tag                      = { key = "Project", value = "demo" }
    object_size_greater_than = 1024       # bytes
    object_size_less_than    = 1048576    # bytes
    and = {                               # cannot be combined with the attributes above
      prefix                   = "logs/"
      tags                     = { Project = "demo" }
      object_size_greater_than = 1024
      object_size_less_than    = 1048576
    }

  Storage classes: STANDARD_IA, INTELLIGENT_TIERING, ONEZONE_IA, GLACIER_IR, GLACIER, DEEP_ARCHIVE
EOF

  type = map(object({
    enabled = optional(bool, true)

    filter = optional(object({
      prefix                   = optional(string)
      tag                      = optional(object({ key = string, value = string }))
      object_size_greater_than = optional(number)
      object_size_less_than    = optional(number)
      and = optional(object({
        prefix                   = optional(string)
        tags                     = optional(map(string))
        object_size_greater_than = optional(number)
        object_size_less_than    = optional(number)
      }))
    }), {})

    transitions                        = optional(map(number), {})
    expiration_days                    = optional(number)
    noncurrent_version_transitions     = optional(map(number), {})
    noncurrent_version_expiration_days = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for rule in values(var.lifecycle_rules) : [
        for storage_class in concat(keys(rule.transitions), keys(rule.noncurrent_version_transitions)) :
        contains(["STANDARD_IA", "INTELLIGENT_TIERING", "ONEZONE_IA", "GLACIER_IR", "GLACIER", "DEEP_ARCHIVE"], storage_class)
      ]
    ]))
    error_message = "lifecycle_rules transitions/noncurrent_version_transitions keys must be one of: STANDARD_IA, INTELLIGENT_TIERING, ONEZONE_IA, GLACIER_IR, GLACIER, DEEP_ARCHIVE."
  }

  validation {
    condition = alltrue([
      for rule in values(var.lifecycle_rules) :
      rule.filter.and == null || (
        rule.filter.prefix == null &&
        rule.filter.tag == null &&
        rule.filter.object_size_greater_than == null &&
        rule.filter.object_size_less_than == null
      )
    ])
    error_message = "lifecycle_rules filter.and cannot be combined with filter.prefix, filter.tag or filter.object_size_*. Put every condition inside filter.and."
  }
}

variable "transition_default_minimum_object_size" {
  type        = string
  description = "(Optional) The default minimum object size behavior applied to the lifecycle configuration. Valid values: all_storage_classes_128K (default), varies_by_storage_class. To customize the minimum object size for any transition you can add a filter that specifies a custom object_size_greater_than or object_size_less_than value. Custom filters always take precedence over the default transition behavior."
  default     = "all_storage_classes_128K"
}
