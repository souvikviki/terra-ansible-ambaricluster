variable "aws_region" {}
variable "aws_profile" {}
data "aws_availability_zones" "available" {}
variable "vpc_cidr" {}

variable "cidrs" {
  type = "map"
}

variable "public_key_path" {}
variable "dev_instance_type" {}
variable "dev_ami" {}
variable "key_name" {}
