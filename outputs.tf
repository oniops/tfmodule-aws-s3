output "bucket_name" {
  value = local.bucket_name
}

output "bucket_simple_name" {
  value = local.bucket_simple_name
}

output "bucket_id" {
  value = try(aws_s3_bucket.this[0].id, "")
}

output "bucket_arn" {
  value = try(aws_s3_bucket.this[0].arn, "")
}

output "local_bucket_arn" {
  value = "arn:aws:s3:::${local.bucket_name}"
}

output "bucket_domain_name" {
  value = try(aws_s3_bucket.this[0].bucket_domain_name, "")
}

output "bucket_regional_domain_name" {
  value = try(aws_s3_bucket.this[0].bucket_regional_domain_name, "")
}

output "versioning_status" {
  value = local.bucket_versioning_status
}

output "enable_versioning_status" {
  value = local.enable_versioning_status
}

output "bucket_policy" {
  value = try(data.aws_iam_policy_document.pols[0].json, "")
}
