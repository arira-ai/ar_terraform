module "ec2" {
  source        = "../../modules/ec2"
  region        = "eu-central-1"
  env           = "dev"
  instance_name = "dev-frankfurt-ec2"
  ami_id        = var.ami_id
}
