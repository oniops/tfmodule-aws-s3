variable "context" {
  type = object({
    project     = string
    region      = string
    environment = string
    department  = string
    domain      = string
    pri_domain  = string
    tags        = map(string)
  })
}
