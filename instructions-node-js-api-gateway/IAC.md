# IaC

## Start with a main.tf file

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "images" {
  bucket = "images-test-js-WORKSHOP"
  acl    = "public-read"
  versioning {
    enabled = true
  }

}
```

## Create role and policy for Lambda

```hcl
#iam role for lambda function
resource "aws_iam_role" "lambda" {
  name               = "lambda_image_WORKSHOP"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#iam policy for lambda function to invoke api gateway and s3
resource "aws_iam_role_policy" "lambda" {
  name   = "lambda_image_WORKSHOP"
  role   = aws_iam_role.lambda.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:listBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.images.id}",
        "arn:aws:s3:::${aws_s3_bucket.images.id}/*"
      ]
    }
    ]
}
EOF
}
```

## Create lambda saver and sender
  
  ```hcl
  #lambda function that receives images and saves them to s3
  resource "aws_lambda_function" "image_saver" {
    function_name    = "image_saver"
    role             = aws_iam_role.lambda.arn
    handler          = "index.handler"
    runtime          = "nodejs14.x"
    filename         = "files/image_receiver.zip"
    source_code_hash = filebase64sha256("files/image_receiver.zip")
    environment {
      variables = {
        BUCKET_NAME = aws_s3_bucket.images.id
      }
    }
  }

  #permission for api gateway to invoke lambda
  resource "aws_lambda_permission" "permission_for_saver" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.image_saver.function_name
    principal     = "apigateway.amazonaws.com"

    # The /*/* portion grants access from any method on any resource
    # within the specified API Gateway.
    source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/*"
  }

  #lambda function that sends images to the client
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
```

## Create front end

```hcl
#s3 bucket statis page for front end
resource "aws_s3_bucket_object" "index" {
  bucket = aws_s3_bucket.images.id
  key    = "index.html"
  content = templatefile("${path.module}/files/index.html", {
    upload_address = "${aws_api_gateway_deployment.api.invoke_url}/images",
    api_address    = "${aws_api_gateway_deployment.api.invoke_url}/images_sender",
    bucket_url     = "${aws_api_gateway_deployment.api.invoke_url}/s3_bucket/"
  })
  etag         = md5(file("files/index.html"))
  content_type = "text/html"
}

#s3 bucket policy to allow public access
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.images.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.images.id}/*"
    }
  ]
}
POLICY
}

#s3 bucket website configuration to serve static page
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.images.id
  index_document {
    suffix = "index.html"
  }
}
```


## Create API Gateway

```hcl
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
  uri                     = aws_lambda_function.image_saver.invoke_arn #arn of lambda image_save function
}

#api gateway integration for images_sender
resource "aws_api_gateway_integration" "images_sender" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.images_sender.id
  http_method             = aws_api_gateway_method.images_sender.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.image_sender.invoke_arn #arn of lambda image_sender function
}

#api gateway integration for s3_bucket
resource "aws_api_gateway_integration" "s3_bucket" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.s3_bucket.id
  http_method             = aws_api_gateway_method.s3_bucket.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}/" #s3 bucket website endpoint
}

#api gateway integration for s3_bucket images
resource "aws_api_gateway_integration" "s3_bucket_images" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.s3_bucket_images.id
  http_method             = aws_api_gateway_method.s3_bucket_images.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}/images/{proxy}" #s3 bucket website endpoint for images
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

#api gateway frontend url output
output "api_gateway_url" {
  value = "${aws_api_gateway_deployment.api.invoke_url}/s3_bucket"
}
```

## Initialize Terraform

```bash
terraform init
```

## Create a plan

```bash

terraform plan
```

## Apply the plan

```bash
terraform apply
```
