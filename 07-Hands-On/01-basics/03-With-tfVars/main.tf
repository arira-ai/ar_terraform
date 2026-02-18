resource "aws_instance" "demo" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = merge(
    local.common_tags,
    {
      Name = "tf-simple-ec2"
    }
  )
}
