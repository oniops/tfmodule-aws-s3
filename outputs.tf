output "bucket" {
  value = try(aws_s3_bucket.this[0].bucket, "")
}

output "bucket_id" {
  value = try(aws_s3_bucket.this[0].id, "")
}

output "bucket_arn" {
  value = try(aws_s3_bucket.this[0].arn, "")
}
