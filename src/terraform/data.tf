data "aws_ami" "amzn-linux-ecs" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami*amazon-ecs-optimized"]
  }

  owners = ["amazon"]
}

data "aws_caller_identity" "current" {}
