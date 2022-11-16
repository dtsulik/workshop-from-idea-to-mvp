# IaC

## Terraform

Since we are using Terraform, we need to install it. You can find the installation instructions [here](https://learn.hashicorp.com/tutorials/terraform/install-cli).

## Provider
Since we are working with AWS, we need to install the AWS provider. You can find the installation instructions [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

Pick your favorite region. I am using `us-east-1` for this example.

```hcl
provider "aws" {
  region = "us-east-1"
}
```

### Lambda

This is the engine of our product. For each endpoint that we think of we will create a Lambda function.


First we declare module creating lambda function `source` tells terraform where to find the module.
```hcl
module "lambda_function_output" {
  source = "terraform-aws-modules/lambda/aws"
  ...
```

`function_name` and `description` to identify the function and it's purpose.
```hcl
  ...
  function_name                 = "lambda-name"
  description                   = "Some meaningful description"
  ...
```

Handler is the name of executable that will get invoked in case of compiled language like `go`. `runtime` is the language that we are using.

```hcl
  ...
  handler                       = "main"
  runtime                       = "go1.x"
  ...
```
If you are using `python` or `nodejs` you specify the function name with format `filename`.`function` that will handle the request. Below example means `handler` function is located in `index.js` file.
```hcl
  ...
  handler                       = "index.handler"
  ...
```

`source_path` is path to source code. The directory contents will be packaged in a `zip` archive and uploaded to Lambda. The current module we selected also preserves the archive in `builds` directory.
```hcl
  ...
  source_path                   = "relative/path/to/source"
  ...
```

Module we are using provides handy flags to do additional configuration for our lambda function.

We will be invoking our functions directly without API Gateway. This config tells module to create function url.
```hcl
  ...
  create_lambda_function_url    = true
  ...
```

This tells the module and terraform subsequently, to create a policy that allows write to CloudWatch logs. This module creates lambda execution role by default. We can add additional policies to it.
```hcl
  ...
  attach_cloudwatch_logs_policy = true
  ...
```

We will also need additional policies to allow our lambda to interact with other AWS services. We will add them here.

```hcl
  ...
  attach_policy_json            = true
  policy_json                   = data.aws_iam_policy_document.lambda_s3_access.json
  ...
```

To configure some parameters for our lambda we can use environment variables. In this case we need to tell lambda which bucket to use for storing images.
```hcl
  environment_variables = {
    BUCKET_NAME = module.s3_bucket.s3_bucket_id
  }
```

Since we are not using APIGW we need to allow other domains to access our function url. Read about CORS [here](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).
```hcl
  cors = {
    allow_origins = ["*"]
  }
}
```

The policy mentioned above can be created using `aws_iam_policy_document` data source. We will create a policy that allows our lambda to read and write to S3 bucket.

```hcl
data "aws_iam_policy_document" "lambda_s3_access" {
  statement {
    sid = "1"
  ..
```

We are telling AWS that we want to perform any s3 related action.
```hcl
    actions = [
      "s3:*",
    ]
```

We are also specifying bucket name and object prefix. In this case any `*` prefix or name. S3 bucket ARN (Amazon Resource Name) is taken from s3 module below.
```hcl
    resources = [
      "${module.s3_bucket.s3_bucket_arn}/*",
    ]
  }
}
```

End result should look like this:
```hcl
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

module "lambda_function_output" {
  source = "terraform-aws-modules/lambda/aws"

  function_name                 = "lambda-name"
  description                   = "Some meaningful description"
  handler                       = "main"
  runtime                       = "go1.x"
  source_path                   = "relative/path/to/source"
  create_lambda_function_url    = true
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
```

### S3

Core of this excersize is to store and retreive images from S3 bucket.

```hcl
data "aws_iam_policy_document" "s3_access" {
  statement {
    sid = "1"

    actions = [
      "s3:*",
    ]

    resources = [
      module.s3_bucket.s3_bucket_arn,
    ]

    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::589295909756:role/workshop-intake", "arn:aws:iam::589295909756:role/workshop-output"]
    }
  }
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  force_destroy = true
  bucket        = "workshop-bucket"

  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_access.json
}
```

### DynamoDB

Config table will be used to store configuration for the GIF generator.

```hcl
module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name = "workshop-table"
  hash_key = "id"
  range_key = "path"
  read_capacity = 5
  write_capacity = 5
  attributes = [
    {
      name = "id"
      type = "S"
    },
    {
      name = "path"
      type = "S"
    }
  ]
}
```

### SQS
Optionally we can also use SQS to queue requests for the GIF generator.

```hcl
module "sqs_queue" {
  source = "terraform-aws-modules/sqs/aws"
  name   = "workshop-queue"
}
```
