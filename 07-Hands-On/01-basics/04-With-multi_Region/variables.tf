variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 instances"
}

variable "ami_id" {
  type        = string
  description = "AMI ID per region"
}

variable "project_name" {
  type        = string
}

variable "owner" {
  type        = string
}

variable "default_tags" {
  type        = map(string)
}