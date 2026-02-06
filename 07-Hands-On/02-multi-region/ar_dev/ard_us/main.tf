module "ec2" {
  source        = "../../modules/ec2"
  region        = "us-east-1"
  env           = "dev"
  instance_name = "dev-virginia-ec2"
  ami_id        = var.ami_id
}
