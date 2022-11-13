data "aws_iam_policy_document" "lambda_s3_access" {
  statement {
    sid = "1"

    actions = [
      "s3:*",
    ]

    resources = [
      "${module.s3_bucket.s3_bucket_arn}/*",
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
  policy_json                   = data.aws_iam_policy_document.lambda_s3_access.json
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
  policy_json                   = data.aws_iam_policy_document.lambda_s3_access.json
  environment_variables = {
    BUCKET_NAME = module.s3_bucket.s3_bucket_id
  }

  cors = {
    allow_origins = ["*"]
  }
}
