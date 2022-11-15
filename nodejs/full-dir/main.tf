terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = var.region
}

#s3 bucket for images
resource "aws_s3_bucket" "images" {
  bucket = "images-test-js-toko"
  acl    = "public-read"
  versioning {
    enabled = true
  }

  force_destroy = true
}

#iam role for lambda function
resource "aws_iam_role" "lambda" {
  name               = "lambda_image_toko"
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
  name   = "lambda_image_toko"
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
