terraform {
  backend "s3" {
    bucket         = "arira-terraform-state"
    key            = "ec2/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
