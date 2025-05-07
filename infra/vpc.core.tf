resource "aws_vpc" "core" {
  cidr_block           = local.core_vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${terraform.workspace}-core-vpc"
  }
}


# 10.0.0.0   : Network Address (reserved)
# 10.0.0.1   : VPC Router (reserved)
# 10.0.0.2   : DNS Server (reserved)
# 10.0.0.3   : Future Use (reserved)
# 10.0.0.4   : First usable IP address
# ...
# 10.0.0.254 : Last usable IP address
# 10.0.0.255 : Network Broadcast Address (reserved)
# Each subnet will have 251 usable IP addresses.
resource "aws_subnet" "core_private" {
  count             = local.core_az_count
  vpc_id            = aws_vpc.core.id
  cidr_block        = cidrsubnet(local.core_vpc_cidr, 8, count.index)
  availability_zone = "${local.core_region}${local.az_suffix[count.index]}"

  tags = {
    Name = "${terraform.workspace}-core-subnet-private-${local.az_suffix[count.index]}"
  }
}



resource "aws_subnet" "core_public" {
  count             = local.core_az_count
  vpc_id            = aws_vpc.core.id
  cidr_block        = cidrsubnet(local.core_vpc_cidr, 8, count.index + local.core_az_count + 10)
  availability_zone = "${local.core_region}${local.az_suffix[count.index]}"

  tags = {
    Name = "${terraform.workspace}-core-subnet-public-${local.az_suffix[count.index]}"
  }
}


resource "aws_route_table" "core_public" {
  vpc_id = aws_vpc.core.id

  tags = {
    Name = "${terraform.workspace}-core-public-rt"
  }
}

resource "aws_route_table" "core_private" {
  count  = local.core_az_count
  vpc_id = aws_vpc.core.id

  tags = {
    Name = "${terraform.workspace}-core-private-rt-${local.az_suffix[count.index]}"
  }
}

resource "aws_route_table_association" "core_public" {
  count          = local.core_az_count
  subnet_id      = aws_subnet.core_public[count.index].id
  route_table_id = aws_route_table.core_public.id
}


resource "aws_route_table_association" "core_private" {
  count          = local.core_az_count
  subnet_id      = aws_subnet.core_private[count.index].id
  route_table_id = aws_route_table.core_private[count.index].id
}


resource "aws_internet_gateway" "core" {
  vpc_id = aws_vpc.core.id

  tags = {
    Name = "${terraform.workspace}-core-igw"
  }
}

resource "aws_route" "core_public_internet_access" {
  route_table_id         = aws_route_table.core_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.core.id
}


resource "aws_nat_gateway" "core" {
  count         = local.core_az_count
  subnet_id     = aws_subnet.core_public[count.index].id
  allocation_id = aws_eip.core[count.index].id
  tags = {
    Name = "${terraform.workspace}-core-ngw-${local.az_suffix[count.index]}"
  }
}

resource "aws_eip" "core" {
  count  = local.core_az_count
  domain = "vpc"
  tags = {
    Name = "${terraform.workspace}-core-nat-eip-${local.az_suffix[count.index]}"
  }
}


resource "aws_route" "core_private_internet_access" {
  count                  = local.core_az_count
  route_table_id         = aws_route_table.core_private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.core[count.index].id
}

