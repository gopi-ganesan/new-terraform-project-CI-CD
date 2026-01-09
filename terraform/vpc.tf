data "aws_vpc" "main" {
    default = true
}

data "aws_subnets" "default" {
    filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
    }
}


resource "aws_security_group" "frontend_sg" {
    name        = "frontend-sg"
    description = "Allow HTTP traffic to frontend"
    vpc_id      = data.aws_vpc.main.id

    ingress {
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
}

resource "aws_security_group" "backend_sg" {
    name        = "backend-sg"
    description = "Allow backend access only from frontend"
    vpc_id      = data.aws_vpc.main.id

    ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
    }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "admin_sg" {
    name        = "admin-sg"
    description = "Allow HTTP traffic to admin"
    vpc_id      = data.aws_vpc.main.id

    ingress {
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
}