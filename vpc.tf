data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc-K8s" {
  cidr_block = var.cidr
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-${var.vpc_name}" })
  )
}

resource "aws_internet_gateway" "igw-vpc-K8s" {
  vpc_id = aws_vpc.vpc-K8s.id
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-IGW-VPC-K8s" })
  )
}

#-------------Public Subnets and Routing----------------------------------------
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.vpc-K8s.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-VPC-K8s-public-${count.index + 1}" })
  )
}


resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.vpc-K8s.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-vpc-K8s.id
  }
  route {
    cidr_block = aws_
  }
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-VPC-K8s-route-public-subnets" })
  )
}

resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}

#-----NAT Gateways with Elastic IPs--------------------------


resource "aws_eip" "nat-eip" {
  count  = length(var.private_subnets)
  domain = "vpc"
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-Eip-K8s-${count.index + 1}" })
  )
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnets)
  allocation_id = aws_eip.nat-eip[count.index].id
  subnet_id     = element(aws_subnet.private_subnets[*].id, count.index)
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-NAT-K8s-${count.index + 1}" })
  )
}


#-------------Private Subnets and Routing----------------------------------------
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.vpc-K8s.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-VPC-K8s-private-${count.index + 1}" })
  )
}


resource "aws_route_table" "private_subnets_rt" {
  vpc_id = aws_vpc.vpc-K8s.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-VPC-K8s-route-private-subnets" })
  )
}

resource "aws_route_table_association" "private_routers" {
  count          = length(aws_subnet.private_subnets[*].id)
  route_table_id = aws_route_table.private_subnets_rt.id
  subnet_id      = element(aws_subnet.private_subnets_rt[*].id, count.index)
}