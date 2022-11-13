data "aws_iam_policy_document" "lambda_resource_access" {
  statement {
    sid = "S3Access"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:ListObjects",
    ]

    resources = [
      "${module.s3_bucket.s3_bucket_arn}/*",
      module.s3_bucket.s3_bucket_arn
    ]
  }
  statement {
    sid = "SQSAccess"

    actions = [
      "sqs:SendMessage",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage", 
    ]

    resources = [
      module.request_queue.sqs_queue_arn
    ]
  }
}

module "lambda_function_intake" {
  source = "terraform-aws-modules/lambda/aws"

  function_name                 = "dtsulik-workshop-intake"
  description                   = "Intake for images"
  handler                       = "main"
  runtime                       = "go1.x"
  create_lambda_function_url    = true
  source_path                   = "../lambdas/intake/"
  attach_cloudwatch_logs_policy = true
  attach_policy_json            = true
  policy_json                   = data.aws_iam_policy_document.lambda_resource_access.json
  environment_variables = {
    BUCKET_NAME = module.s3_bucket.s3_bucket_id
  }

  cors = {
    allow_origins = ["*"]
  }
}

module "lambda_function_output" {
  source = "terraform-aws-modules/lambda/aws"

  function_name                 = "dtsulik-workshop-output"
  description                   = "Output for images"
  handler                       = "main"
  runtime                       = "go1.x"
  create_lambda_function_url    = true
  source_path                   = "../lambdas/output/"
  attach_cloudwatch_logs_policy = true
  attach_policy_json            = true
  policy_json                   = data.aws_iam_policy_document.lambda_resource_access.json
  environment_variables = {
    BUCKET_NAME = module.s3_bucket.s3_bucket_id
  }

  cors = {
    allow_origins = ["*"]
  }
}

module "lambda_function_request" {
  source = "terraform-aws-modules/lambda/aws"

  function_name                 = "dtsulik-workshop-request"
  description                   = "Output for images"
  handler                       = "main"
  runtime                       = "go1.x"
  create_lambda_function_url    = true
  source_path                   = "../lambdas/request/"
  attach_cloudwatch_logs_policy = true
  attach_policy_json            = true
  policy_json                   = data.aws_iam_policy_document.lambda_resource_access.json
  environment_variables = {
    QUEUE_URL = module.request_queue.sqs_queue_id
  }

  cors = {
    allow_origins = ["*"]
  }
}
