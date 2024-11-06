resource "aws_network_acl" "web_server_acl" {
  vpc_id = aws_vpc.vpc-k8s.id

  # Inbound Rules
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0" # Changed this to allow SSH from anywhere
    from_port  = 22
    to_port    = 22
  }

  ingress {
    rule_no    = 130
    protocol   = "icmp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    icmp_type  = -1
    icmp_code  = -1
  }

  ingress {
    rule_no    = 140
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  egress {
    rule_no    = 100
    protocol   = "-1" # Allow all protocols
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-test-ACLs-for-lab" })
  )
}

# Associate the ACL with your subnets
resource "aws_network_acl_association" "web_server_acl_association" {
  count          = length(var.public_subnets)
  network_acl_id = aws_network_acl.web_server_acl.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}