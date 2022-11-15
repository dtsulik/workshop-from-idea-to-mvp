data "aws_caller_identity" "current" {}

variable "region" {
  type        = string
  default     = "eu-central-1"
  description = "Region"
}