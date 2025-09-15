terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1" # Stockholm
}

# --- Get Default VPC ---
data "aws_vpc" "default" {
  default = true
}

# --- Get Default Subnets ---
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security Group for EC2 ---
resource "aws_security_group" "ec2_sg" {
  name_prefix = "tf-ec2-sg-"
  description = "Allow SSH and HTTP access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TF-EC2-SecurityGroup"
  }
}

# --- EC2 Instance ---
resource "aws_instance" "my_ec2" {
  ami                         = "ami-06e6ecbbeb4d04d43" # Amazon Linux 2 for eu-north-1
  instance_type               = "t3.micro"             # Supported type
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name                    = null # No key pair

  tags = {
    Name = "tytyy"
  }
}
