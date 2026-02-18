module "ec2" {
  source = "./"

  aws_region     = var.aws_region
  instance_type = var.instance_type
  instance_count = var.instance_count
  ami_id         = var.ami_id

  project_name = var.project_name
  owner        = var.owner
  default_tags = var.default_tags
}