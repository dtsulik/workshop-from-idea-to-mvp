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
      "sqs:GetQueueAttributes",
    ]

    resources = [
      module.request_queue.sqs_queue_arn
    ]
  }
}

locals {
  build_paths = [
    "../lambdas/intake/",
    "../lambdas/output/",
    "../lambdas/request/",
    "../lambdas/process/",
  ]
}

resource "null_resource" "build" {
  for_each = toset(local.build_paths)
  provisioner "local-exec" {
    command = "cd ${each.key} && rm -f main && GOOS=linux go build main.go"
  }
}

module "lambda_function_intake" {
  depends_on = [null_resource.build]

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
  depends_on = [null_resource.build]
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
  depends_on = [null_resource.build]
  source = "terraform-aws-modules/lambda/aws"

  function_name                 = "dtsulik-workshop-request"
  description                   = "Queue requests for images"
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

module "lambda_function_process" {
  depends_on = [null_resource.build]
  source = "terraform-aws-modules/lambda/aws"

  function_name                 = "dtsulik-workshop-process"
  description                   = "Process requests"
  handler                       = "main"
  runtime                       = "go1.x"
  create_lambda_function_url    = true
  source_path                   = "../lambdas/process/"
  attach_cloudwatch_logs_policy = true
  attach_policy_json            = true
  policy_json                   = data.aws_iam_policy_document.lambda_resource_access.json
  environment_variables = {
    BUCKET_NAME = module.request_queue.sqs_queue_id
  }

  cors = {
    allow_origins = ["*"]
  }
}

resource "aws_lambda_event_source_mapping" "sqs_event_mapping" {
  event_source_arn = module.request_queue.sqs_queue_arn
  function_name    = module.lambda_function_process.lambda_function_arn
}
