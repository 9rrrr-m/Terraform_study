output "s3_bucket_arn" {
  value = aws_s3_bucket.myBucket.arn
  description = "S3 Bucket ARN"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.myDyDB.name
  description = "DynamoDB Table name"
}
