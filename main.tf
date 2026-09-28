data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # One subnet per (network, AZ). The VPC /16 is cut into /20 blocks per
  # network, and each /20 is cut into /24s per AZ.
  subnets = {
    for pair in setproduct(keys(var.networks), range(var.az_count)) :
    "${pair[0]}-${pair[1]}" => {
      network = pair[0]
      az      = local.azs[pair[1]]
      cidr    = cidrsubnet(cidrsubnet(var.vpc_cidr, 4, var.networks[pair[0]]), 4, pair[1])
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_subnet" "this" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.network
    Tier = each.value.network
  }
}

# One route table per network, each with a default route to the IGW so every
# network has outbound internet access.
resource "aws_route_table" "this" {
  for_each = var.networks

  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.vpc_name}-${each.key}-rt"
    Tier = each.key
  }
}

resource "aws_route_table_association" "this" {
  for_each = local.subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.this[each.value.network].id
}
