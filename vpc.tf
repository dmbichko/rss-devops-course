# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc-k8s" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-${var.vpc_name}" })
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw_vpc_k8s" {
  vpc_id = aws_vpc.vpc-k8s.id
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-IGW-vpc-k8s" })
  )
}

#-------------Public Subnets and Routing----------------------------------------
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.vpc-k8s.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-vpc-k8s-public-${count.index + 1}" })
  )
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc-k8s.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc_k8s.id
  }

  tags = merge(
    local.common_tags,
    { Name = "${local.prefix}-vpc-k8s-route-public-subnets" }
  )
}

# Public Route Table Association
resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnets[count.index].id
}

# NAT Gateways with Elastic IPs
/*resource "aws_eip" "nat-eip" {
  count  = length(var.private_subnets)
  domain = "vpc"
  tags = merge(
    local.common_tags,
    { Name = "${local.prefix}-EIP-K8s-${count.index + 1}" }
  )
}*/

/*resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnets)
  allocation_id = aws_eip.nat-eip[count.index].id
  subnet_id     = element(aws_subnet.private_subnets[*].id, count.index)
  tags = merge(
    local.common_tags,
    { Name = "${local.prefix}-NAT-K8s-${count.index + 1}" }
  )

  depends_on = [aws_internet_gateway.igw_vpc_k8s]
}*/

#-------------Private Subnets and Routing----------------------------------------
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.vpc-k8s.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-vpc-k8s-private-${count.index + 1}" })
  )
}

# Private Route Tables
resource "aws_route_table" "private_rt" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.vpc-k8s.id
  /*  route {
    cidr_block  = "0.0.0.0/0"
    network_interface_id = element(aws_network_interface.nat[*].id, count.index)
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }*/
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-vpc-k8s-route-private-subnets" })
  )
}

resource "aws_network_interface" "nat_eni" {
  count             = length(var.public_subnets)
  subnet_id         = aws_subnet.public_subnets[count.index].id
  security_groups   = [aws_security_group.nat_sg.id]
  source_dest_check = false

  tags = merge(
    local.common_tags,
    { Name = "${local.prefix}-NAT-ENI-${count.index + 1}" }
  )
}
resource "aws_route" "private_nat_route" {
  count                  = length(var.private_subnets)
  route_table_id         = aws_route_table.private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.nat_eni[count.index].id
}

# Private Route Table Association
resource "aws_route_table_association" "private_routers" {
  count          = length(aws_subnet.private_subnets[*].id)
  route_table_id = aws_route_table.private_rt[count.index].id
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
}


# Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc-k8s.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private_subnets[*].id
}