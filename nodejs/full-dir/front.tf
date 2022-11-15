#s3 bucket statis page
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

#s3 bucket policy
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

#s3 bucket website
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.images.id
  index_document {
    suffix = "index.html"
  }
}