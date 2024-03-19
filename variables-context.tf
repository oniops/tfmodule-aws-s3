variable "context" {
  type = object({
    project          = string
    region           = string
    account_id       = string
    name_prefix      = string
    s3_bucket_prefix = string
    environment      = string
    team             = string
    domain           = string
    pri_domain       = string
    tags             = map(string)
  })
}
