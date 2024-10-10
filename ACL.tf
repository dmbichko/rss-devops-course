resource "aws_network_acl" "web_server_acl" {
  vpc_id = aws_vpc.vpc-K8s.id
  
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
    cidr_block = ["${var.your_ip}"]  # Replace with your specific IP range
    from_port  = 22
    to_port    = 22
  }

  # Outbound Rules
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-test-ACLs-for-lab" })
  )
}

# Associate the ACL with your subnets
resource "aws_network_acl_association" "web_server_acl_association" {
  count                   = length(var.public_subnets)
  network_acl_id = aws_network_acl.web_server_acl.id
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)  
}