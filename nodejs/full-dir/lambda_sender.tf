#lambdas that displays images from s3
resource "aws_lambda_function" "image_sender" {
  function_name    = "image_sender"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  filename         = "files/image_sender.zip"
  source_code_hash = filebase64sha256("files/image_sender.zip")
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.images.id
    }
  }
}

#permission for api gateway to invoke lambda
resource "aws_lambda_permission" "permission_for_sender" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_sender.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the specified API Gateway.
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/*"
}