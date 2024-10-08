resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"

  vpc_id = aws_vpc.vpc-K8s.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Indicates all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_icmp" {
  name        = "allow-icmp"
  description = "Allow icmp inbound traffic and all outbound traffic"

  vpc_id = aws_vpc.vpc-K8s.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ICMP from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Indicates all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_all_privata_sub" {
  name        = "allow-all"
  description = "Allow all inbound traffic from VPC and all outbound traffic"

  vpc_id = aws_vpc.vpc-K8s.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr}"]
    description = "Allow ALL from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Indicates all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}