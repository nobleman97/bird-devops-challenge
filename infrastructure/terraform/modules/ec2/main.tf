data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_instance" "this" {
  ami = data.aws_ami.ubuntu.id

  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = var.security_groups

  iam_instance_profile = var.iam_instance_profile

  user_data = file(var.user_data)

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  lifecycle {
    ignore_changes = [
      ami
    ]
  }

  tags = {
    Name = var.instance_name
  }
}
