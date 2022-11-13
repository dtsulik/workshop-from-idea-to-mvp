output "s3_bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}

output "intake_url" {
  value = module.lambda_function_intake.lambda_function_url
}

output "output_url" {
  value = module.lambda_function_output.lambda_function_url
}
