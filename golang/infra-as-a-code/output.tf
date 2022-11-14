output "s3_bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}

output "intake_url" {
  value = module.lambda_function_intake.lambda_function_url
}

output "output_url" {
  value = module.lambda_function_output.lambda_function_url
}

output "request_url" {
  value = module.lambda_function_request.lambda_function_url
}

output "process_url" {
  value = module.lambda_function_process.lambda_function_url
}

output "sqs_queue_url" {
  value = module.request_queue.sqs_queue_id
}