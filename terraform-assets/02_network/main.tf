/* This file describes:

- aws_vpc
- aws_internet_gateway
- data.aws_availability_zones
- aws_db_subnet_group

Public Subnets
- length(var.public_nets) x aws_subnet public
- length(var.public_nets) x aws_eip
- length(var.public_nets) x aws_nat_gateway
- 1 x aws_route_table public
- 1 x aws_route_table_association public
- 1 x aws_route public

Private Subnets
- length(var.private_nets) x aws_subnet private
- length(aws_nat_gateway.nat) x aws_route_table private
- length(var.private_nets) x aws_route_table_association private
- length(aws_nat_gateway.nat) x aws_route private

*/

resource "aws_vpc" "vpc" {

  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.app_name}-vpc"
    Environment = var.app_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  count                   = length(var.public_nets) > 0 ? length(var.public_nets) : 0
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  cidr_block              = element(var.public_nets, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.app_name}-public"
    Environment = var.app_name
  }
}

resource "aws_subnet" "private" {
  count                   = length(var.private_nets) > 0 ? length(var.private_nets) : 0
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  cidr_block              = element(var.private_nets, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.app_name}-private"
    Environment = var.app_name
  }
}

resource "aws_db_subnet_group" "rds_private" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = aws_subnet.private.*.id
  tags = {
    Name = "RDS_subnet_group"
  }
}

resource "aws_eip" "nat" {
  count = length(var.public_nets)
  vpc   = true
  tags = {
    Name        = "${var.app_name}-eip"
    Environment = var.app_name
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.public_nets)
  subnet_id     = element(aws_subnet.public.*.id, count.index) #aws_subnet.public[0].id
  allocation_id = element(aws_eip.nat.*.id, count.index)       #aws_eip.nat.id

  tags = {
    Name        = "${var.app_name}-ecs-gw-nat"
    Environment = var.app_name
  }
}

## Routing tables for  Public and Private subnets.

# PUBLIC
# create one table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.app_name}-vpc"
    Environment = var.app_name
  }
}

# Associate routing table with subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_nets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# Add routing rules to routing tables
resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# PRIVATE
# create two tables (one per nat_gw)
resource "aws_route_table" "private" {
  count  = length(aws_nat_gateway.nat)
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "private"
  }
}

# Associate routing table with subnets
resource "aws_route_table_association" "private" {
  count          = length(var.private_nets)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

# Add routing rules to routing tables
resource "aws_route" "private_nat" {
  count                  = length(aws_nat_gateway.nat)
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id, count.index) #aws_nat_gateway.nat.id
}

# usually is needed to create some vpce-s3 endpoint, but I don't need s3 here yet
