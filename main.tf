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
  region = "ap-south-1"
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
  name_prefix = "ec2-sg-"  # Auto-generate unique name
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
    Name = "EC2SecurityGroup"
  }
}

# --- EC2 Instance ---
resource "aws_instance" "my_ec2" {
  ami                         = "ami-0b982602dbb32c5bd"
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name                    = null # No key pair

  tags = {
    Name = "MyTerraformEC2"
  }
}

# --- Security Group for RDS ---
resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg-"  # Auto-generate unique name
  description = "Allow MySQL access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDSSecurityGroup"
  }
}

# --- RDS Subnet Group ---
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "my-rds-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "MyRDSSubnetGroup"
  }
}

# --- RDS MySQL Instance ---
resource "aws_db_instance" "my_rds" {
  identifier              = "myterraformdb"
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = "admin"
  password                = "AdminPass123!" # Replace with a variable or secret
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = true

  tags = {
    Name = "MyTerraformRDS"
  }
}
