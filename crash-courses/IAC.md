# IAC

IAC stands for "Infrastructure as Code". It's a way of managing your infrastructure in a way that is version controlled, and can be deployed to multiple environments.

## Terraform crash course

Terraform is one of the most popular tools for IaC. It is a tool that allows you to define your infrastructure as code. It is a declarative language, which means that you define what you want, and Terraform will make sure that it is in that state. It is not imperative, which means that you don't tell Terraform how to do it, you just tell it what you want.

Link to terraform documentation: [https://www.terraform.io/docs/index.html](https://www.terraform.io/docs/index.html)

It's core components are:
- Prodvider is a plugin that allows Terraform to interact with a certain service. For example, AWS provider allows Terraform to interact with AWS services.
- Resource is a single object, like Lambda, or S3 bucket.
- Data source is a way to get information from a service. For example, you can get information about an AMI, or a subnet.
- Variable is quite self-explanatory. It is a variable that you can use in your code.
- Module is a way to reuse code. You can create a module that creates an Lambda, and then use it in your code. You can also use modules that other people have created. 
- Output is a way to get information from your code. For example, you can get the ARN of a Lambda, or the URL of an API Gateway.
