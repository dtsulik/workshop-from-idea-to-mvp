module "request_queue" {
  source                     = "terraform-aws-modules/sqs/aws"
  name                       = "workshop-request-queue"
  visibility_timeout_seconds = 60
}
