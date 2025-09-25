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
  value = local.pols
}

output "replication_role_arn" {
  description = "ARN of the IAM role for S3 replication"
  value       = local.create_replication_role ? aws_iam_role.replica[0].arn : var.replication_role_arn
}