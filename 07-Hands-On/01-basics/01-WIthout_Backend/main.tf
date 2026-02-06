terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "simple_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "simple-ec2"
  }
}
