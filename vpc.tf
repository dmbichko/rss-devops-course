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
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-VPC-K8s-route-public-subnets-${count.index + 1}" })
  )
}

resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}