resource "aws_s3_bucket" "python_bucket" {
  bucket        = "tf-bucket-for-python-begginers"
  force_destroy = true

  tags = {
    Name        = "python begginers"
    Environment = "test"
  }
}

resource "aws_s3_bucket_website_configuration" "python_bucket" {
  bucket = aws_s3_bucket.python_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.python_bucket.id
  policy = data.aws_iam_policy_document.public.json
}

data "aws_iam_policy_document" "public" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      aws_s3_bucket.python_bucket.arn,
      "${aws_s3_bucket.python_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_object" "html_upload" {
    for_each = fileset("html/", "*")
    bucket = aws_s3_bucket.python_bucket.id
    key = each.value
    source = "html/${each.value}"
    content_type = "text/html"
    etag = filemd5("html/${each.value}")
}