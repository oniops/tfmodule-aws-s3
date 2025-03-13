locals {
  add_custom_policy = var.attach_custom_policy != null
  attach_policy     = var.attach_deny_insecure_transport_policy || var.attach_deny_incorrect_encryption_headers || var.attach_lb_log_delivery_policy || var.attach_access_log_delivery_policy || local.add_custom_policy
  #  || var.attach_require_latest_tls_policy
  #  || var.attach_inventory_destination_policy
  #  || var.attach_deny_incorrect_kms_key_sse
  #  || var.attach_deny_unencrypted_object_uploads

  pols = var.create && local.attach_policy ? jsonencode({
    Version = "2012-10-17"
    Statement = concat(
        var.attach_deny_insecure_transport_policy ? tolist(jsondecode(local.policy_deny_insecure_transport)) : [],
        var.attach_deny_incorrect_encryption_headers ? tolist(jsondecode(local.policy_deny_incorrect_encryption)) : [],
        var.attach_lb_log_delivery_policy ? tolist(jsondecode(local.policy_allow_lb_log_delivery)) : [],
        var.attach_access_log_delivery_policy ? tolist(jsondecode(local.policy_allow_access_log_delivery)) : [],
        var.attach_elb_log_delivery_policy ? tolist(jsondecode(local.policy_allow_elb_log_delivery)) : [],
        local.add_custom_policy ? tolist(jsondecode(var.attach_custom_policy)) : []
    )
  }) : null
}

resource "aws_s3_bucket_policy" "this" {
  count = var.create && local.attach_policy ? 1 : 0

  # Chain resources (s3_bucket -> s3_bucket_public_access_block -> s3_bucket_policy )
  # to prevent "A conflicting conditional operation is currently in progress against this resource."
  # Ref: https://github.com/hashicorp/terraform-provider-aws/issues/7628
  bucket = aws_s3_bucket.this[0].id
  policy = local.pols
  depends_on = [
    aws_s3_bucket_public_access_block.this
  ]
}
