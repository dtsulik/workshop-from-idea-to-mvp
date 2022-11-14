module "request_queue" {
  source = "terraform-aws-modules/sqs/aws"
  name   = "dtsulik-workshop-request-queue"
}
