locals {
  attach_policy = var.attach_deny_insecure_transport_policy || var.attach_deny_incorrect_encryption_headers || var.attach_lb_log_delivery_policy || var.attach_access_log_delivery_policy || var.attach_custom_policy
  #  || var.attach_require_latest_tls_policy
  #  || var.attach_inventory_destination_policy
  #  || var.attach_deny_incorrect_kms_key_sse
  #  || var.attach_deny_unencrypted_object_uploads
}


data "aws_iam_policy_document" "pols" {
  count = var.create && local.attach_policy ? 1 : 0

  source_policy_documents = compact([
      var.attach_deny_insecure_transport_policy ? local.policy_deny_insecure_transport : "",
      var.attach_deny_incorrect_encryption_headers ? local.policy_deny_incorrect_encryption : "",
      var.attach_lb_log_delivery_policy ? local.policy_allow_lb_log_delivery : "",
      var.attach_access_log_delivery_policy ? local.policy_allow_access_log_delivery : "",
      var.attach_elb_log_delivery_policy ? local.policy_allow_elb_log_delivery : "",
      var.attach_custom_policy ? var.custom_policy : "",
    #    var.attach_lb_log_delivery_policy ? data.aws_iam_policy_document.lb_log_delivery[0].json : "",
    #    var.attach_access_log_delivery_policy ? data.aws_iam_policy_document.access_log_delivery[0].json : "",
    #    var.attach_require_latest_tls_policy ? data.aws_iam_policy_document.require_latest_tls[0].json : "",
    #    var.attach_deny_unencrypted_object_uploads ? data.aws_iam_policy_document.deny_unencrypted_object_uploads[0].json : "",
    #    var.attach_deny_incorrect_kms_key_sse ? data.aws_iam_policy_document.deny_incorrect_kms_key_sse[0].json : "",
    #    var.attach_inventory_destination_policy || var.attach_analytics_destination_policy ? data.aws_iam_policy_document.inventory_and_analytics_destination_policy[0].json : "",
  ])
}

resource "aws_s3_bucket_policy" "this" {
  count = var.create && local.attach_policy ? 1 : 0

  # Chain resources (s3_bucket -> s3_bucket_public_access_block -> s3_bucket_policy )
  # to prevent "A conflicting conditional operation is currently in progress against this resource."
  # Ref: https://github.com/hashicorp/terraform-provider-aws/issues/7628
  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.pols[0].json
  depends_on = [
    aws_s3_bucket_public_access_block.this
  ]
}
