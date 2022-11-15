#api gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "image-upload-api"
  description = "Saves images to s3"
}

#api gateway resource for images_saver
resource "aws_api_gateway_resource" "images_saver" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "images"
}

#api gateway resource for images_sender
resource "aws_api_gateway_resource" "images_sender" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "images_sender"
}

# api gateway resource for s3 bucket
resource "aws_api_gateway_resource" "s3_bucket" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "s3_bucket"
}

# api gateway resource for s3 images
resource "aws_api_gateway_resource" "s3_bucket_images" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.s3_bucket.id
  path_part   = "{proxy+}"
}

#api gateway method for images_saver
resource "aws_api_gateway_method" "images_saver" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.images_saver.id
  http_method   = "POST"
  authorization = "NONE"
}

#api gateway method for images_sender
resource "aws_api_gateway_method" "images_sender" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.images_sender.id
  http_method   = "GET"
  authorization = "NONE"
}

#api gateway method for s3_bucket
resource "aws_api_gateway_method" "s3_bucket" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.s3_bucket.id
  http_method   = "GET"
  authorization = "NONE"
}

#api gateway method for s3_bucket images
resource "aws_api_gateway_method" "s3_bucket_images" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.s3_bucket_images.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = { "method.request.path.proxy" = true }
}


#api gateway integration for images_saver
resource "aws_api_gateway_integration" "images_saver" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.images_saver.id
  http_method             = aws_api_gateway_method.images_saver.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.image_saver.invoke_arn
}

#api gateway integration for images_sender
resource "aws_api_gateway_integration" "images_sender" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.images_sender.id
  http_method             = aws_api_gateway_method.images_sender.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.image_sender.invoke_arn
}

#api gateway integration for s3_bucket
resource "aws_api_gateway_integration" "s3_bucket" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.s3_bucket.id
  http_method             = aws_api_gateway_method.s3_bucket.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}/"
}

#api gateway integration for s3_bucket images
resource "aws_api_gateway_integration" "s3_bucket_images" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.s3_bucket_images.id
  http_method             = aws_api_gateway_method.s3_bucket_images.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}/images/{proxy}"

  request_parameters = { "integration.request.path.proxy" = "method.request.path.proxy" }
}

#api gateway deployment
resource "aws_api_gateway_deployment" "api" {
  depends_on = [
    aws_api_gateway_integration.images_saver,
    aws_api_gateway_integration.images_sender,
    aws_api_gateway_integration.s3_bucket,
    aws_api_gateway_integration.s3_bucket_images
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "test"
}

output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.api.invoke_url}/s3_bucket"
}