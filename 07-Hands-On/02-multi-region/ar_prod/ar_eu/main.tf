module "ec2" {
  source        = "../../modules/ec2"
  region        = "eu-central-1"
  env           = "prod"
  instance_name = "prod-frankfurt-ec2"
  ami_id        = var.ami_id
}
