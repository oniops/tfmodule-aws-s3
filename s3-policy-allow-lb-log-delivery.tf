locals {
  policy_allow_lb_log_delivery = var.create && var.attach_lb_log_delivery_policy ? templatefile("${path.module}/templates/s3-policy-allow-lb-log-delivery.tpl", {
      bucket_name = local.bucket_name
      region      = local.region
      account_id  = local.account_id
    }) : ""
}
