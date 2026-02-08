data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }
}

locals {
  common_tags = {
    Project = var.project_name
    Owner   = var.owner
    Env     = var.environment
  }
}
