# Always get the latest amazon linux AMI
data "aws_ami" "amazon_linux_latest" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_launch_template" "main" {
  name = "${var.app_name}-${var.env_name}"

  instance_type          = var.ec2_instance_type
  image_id               = data.aws_ami.amazon_linux_latest.id
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  user_data = base64encode(<<EOF
    dnf install -y git
    sudo -u ec2-user git clone https://github.com/CityOfPhiladelphia/grafana-iac.git
    sudo -u ec2-user bash grafana-iac/server/build.sh
    EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = local.default_tags
  }
  tag_specifications {
    resource_type = "volume"
    tags          = local.default_tags
  }
  tag_specifications {
    resource_type = "network-interface"
    tags          = local.default_tags
  }

  tags = local.default_tags
}
