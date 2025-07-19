variable "aws_region" { default = "us-east-1" }
variable "key_name" { description = "Your AWS EC2 SSH Key Name" }
variable "private_key_path" { description = "Path to your private key file" }
# variable "vpc_id" {}
# variable "subnet_id" {}
variable "instance_type" { default = "t3.medium" }
