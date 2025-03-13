locals {
  policy_allow_lb_log_delivery = var.create ? templatefile("${path.module}/templates/s3-policy-allow-lb-log-delivery.tpl", {
      bucket_name = local.bucket_name
      region      = local.region
      account_id  = local.account_id
    }) : ""
}
