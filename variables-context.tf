variable "context" {
  type        = any
  description = <<-EOF

  ex)
  context = {
    project     = "demo"
    region      = "ap-northeast-2"
    environment = "PoC"
    customer    = "My Customer"
    department  = "DevOps"
    team        = "DevOps"
    owner       = "owner@example.com"
    domain      = "example.com"
    pri_domain  = "internal.example.com"
  }
EOF

}
