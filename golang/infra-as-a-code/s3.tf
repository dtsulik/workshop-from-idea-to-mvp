# data "aws_iam_policy_document" "s3_access" {
#   statement {
#     sid = "1"

#     actions = [
#       "s3:*",
#     ]

#     resources = [
#       "${module.s3_bucket.s3_bucket_arn}/*",
#       module.s3_bucket.s3_bucket_arn
#     ]

#     principals {
#       type = "AWS"
#       identifiers = [
#         "arn:aws:iam::589295909756:role/workshop-intake",
#         "arn:aws:iam::589295909756:role/workshop-output"
#       ]
#     }
#   }
# }

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  force_destroy = true
  bucket        = "workshop-bucket"

  # attach_policy = true
  # policy        = data.aws_iam_policy_document.s3_access.json
}