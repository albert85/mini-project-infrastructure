terraform {
  backend "s3" {
    bucket  = "techbleat-cicd-state-bucket-week-7"
    key     = "envs/dev/terraform.tfstate"
    region  = "eu-north-1"
    encrypt = true

  }
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_security_group" "nginx-sg" {
  name        = "nginx-sg"
  description = "Security group for NGINX server"
  vpc_id      = var.project_vpc

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH traffic"
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags = {
        Name = "nginx-sg"
    }
  
}

resource "aws_security_group" "backend-sg" {
  name        = "backend-sg"
  description = "Security group for backend server"
  vpc_id      = var.project_vpc

  ingress {
    description = "Allow HTTP traffic from NGINX server"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    security_groups = [
      aws_security_group.nginx-sg.id
    ]
  }

  ingress {
    description = "Allow SSH traffic"
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags = {
        Name = "backend-sg"
    }
}

#----------------------------
# EC2 Instance (web-server)
#----------------------------

resource "aws_instance" "web-server" {
  ami           = var.project_ami
  instance_type = var.project_instance_type
  subnet_id     = var.project_subnet

  vpc_security_group_ids = [
    aws_security_group.nginx-sg.id
  ]

  key_name = var.project_keyname

  tags = {
    Name = "web-server"
  }
}

#----------------------------
# EC2 Instance (backend-server)
#----------------------------

resource "aws_instance" "backend-server" {
  ami           = var.project_ami
  instance_type = var.project_instance_type
  subnet_id     = var.project_subnet

  vpc_security_group_ids = [
    aws_security_group.backend-sg.id
  ]

  key_name = var.project_keyname

  tags = {
    Name = "backend"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = var.rds_name
  description = "RDS PostgreSQL access"
  vpc_id      = var.project_vpc

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = var.rds_subnet_name
  subnet_ids = [var.project_subnet, var.project_aurora_subnet]
}

resource "aws_db_instance" "postgres" {
  identifier = var.db_identifier

  engine         =var.db_engine


  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = var.db_storage_type

  db_name  = var.db_username
  username = var.db_password
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = true
  multi_az            = false

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "free-tier-postgres"
    Environment = var.environment
  }
}



#----------------------------
# Outputs
#----------------------------

output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web-server.public_ip
}

output "backend_server_public_ip" {
  description = "Public IP of the backend server"
  value       = aws_instance.backend-server.private_ip
}
