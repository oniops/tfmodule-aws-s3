variable "context" {
  type = object({
    project     = string
    region      = string
    environment = string
    team        = string
    domain      = string
    pri_domain  = string
    tags        = map(string)
  })
}
