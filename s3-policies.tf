locals {
  add_custom_policy         = var.attach_custom_policy != null
  add_vpce_policy           = var.source_vpce != null
  add_cloudfront_oac_policy = length(var.cloudfront_distributions_arn) > 0

  # attach_policy is derived only from input variables so it stays known at plan time
  # (count/for_each cannot depend on apply-time values). The rendered policy JSON
  # strings below reference resource ARNs and are only safe to use inside `pols`.
  attach_policy = (
    var.attach_deny_insecure_transport_policy || var.attach_deny_incorrect_encryption_headers
    || var.attach_lb_log_delivery_policy || var.attach_access_log_delivery_policy
    || var.attach_elb_log_delivery_policy || var.attach_aws_inspector_report_policy
    || local.add_vpce_policy || local.add_cloudfront_oac_policy || local.add_custom_policy
  )

  # Each enabled flag contributes a JSON-array string; disabled ones become "" and are
  # dropped by compact(). Adding a new policy = one line here.
  policy_statement_jsons = compact([
    var.attach_deny_insecure_transport_policy ? local.policy_deny_insecure_transport : "",
    var.attach_deny_incorrect_encryption_headers ? local.policy_deny_incorrect_encryption : "",
    var.attach_lb_log_delivery_policy ? local.policy_allow_lb_log_delivery : "",
    var.attach_access_log_delivery_policy ? local.policy_allow_access_log_delivery : "",
    var.attach_elb_log_delivery_policy ? local.policy_allow_elb_log_delivery : "",
    var.attach_aws_inspector_report_policy ? local.policy_allow_aws_inspector : "",
    local.add_vpce_policy ? local.policy_allow_vpce : "",
    local.add_cloudfront_oac_policy ? local.policy_allow_cloudfront_oac : "",
  ])

  # attach_custom_policy is `any` — accept native HCL (list of statements or a single
  # statement object) and JSON-string forms uniformly. The for/if avoids a ternary
  # whose branches would have inconsistent tuple lengths (length-N vs length-0),
  # which Terraform's type-unifier rejects. try() picks whichever decode succeeds;
  # flatten() then normalizes to a flat list of statement objects.
  custom_policy_statements = flatten([
    for v in [var.attach_custom_policy] :
    try(jsondecode(v), v) if v != null
  ])

  # flatten() preserves heterogeneous tuple element types, so policy statements with
  # different shapes (Action/Resource as string vs list, Principal as "*" vs object,
  # varying Condition shapes) merge without the type-unification error that
  # concat() + tolist(jsondecode(...)) raises.
  pols = var.create && local.attach_policy ? jsonencode({
    Version = "2012-10-17"
    Statement = flatten([
      [for s in local.policy_statement_jsons : jsondecode(s)],
      local.custom_policy_statements,
    ])
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
