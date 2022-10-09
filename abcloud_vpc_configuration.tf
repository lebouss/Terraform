
provider "aws" {
  region = local.region
}

locals {
  region = "eu-west-3"
}

################################################################################
# ABCloud VPC
################################################################################

resource "aws_vpc" "abcloud" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy 	= "default"

  tags = {
    Name = "website_vpc"
  }
}

resource "aws_internet_gateway" "abcloud" {
  vpc_id = aws_vpc.abcloud.id

  tags = {
    Name = "website_internet_gateway"
  }
}

################################################################################
# ABCloud Subnet ==> 2 publics and 2 privates in 2 AZ for high availability and safety
################################################################################

#public_subnet_1
resource "aws_subnet" "abcloud_Public_subnet_1" {
  vpc_id		= aws_vpc.abcloud.id
  cidr_block           = "10.0.101.0/24"
  availability_zone 	= "${local.region}a"
  

  tags = {
    Name = "website_public_subnet_1"
  }
}

#public_subnet_2
resource "aws_subnet" "abcloud_Public_subnet_2" {
  vpc_id		= aws_vpc.abcloud.id
  cidr_block           = "10.0.102.0/24"
  availability_zone 	= "${local.region}b"
  

  tags = {
    Name = "website_public_subnet_2"
  }
}

#private_subnet_1
resource "aws_subnet" "abcloud_Private_subnet_1" {
  vpc_id		= aws_vpc.abcloud.id
  cidr_block           = "10.0.1.0/24"
  availability_zone 	= "${local.region}a"
  

  tags = {
    Name = "website_private_subnet_1"
  }
}

#private_subnet_2
resource "aws_subnet" "abcloud_Private_subnet_2" {
  vpc_id		= aws_vpc.abcloud.id
  cidr_block           = "10.0.2.0/24"
  availability_zone 	= "${local.region}b"
  

  tags = {
    Name = "website_private_subnet_2"
  }
}
 
#################################################################################
# ABCloud NatGateway & Eip ==> Communication for private subnet
#################################################################################

#eip_1
#resource "aws_eip" "abcloud_eip_1" {
#  instance = aws_instance.web.id
#  vpc      = true
#}

#eip_2
#resource "aws_eip" "abcloud_eip_2" {
#  vpc      = true
#}

#nat_gateway_1
resource "aws_nat_gateway" "abcloud_nat_gateway_1" {
  connectivity_type = "private"
  #allocation_id = aws_eip.aws_eip.abcloud_eip_1.id
  subnet_id     = aws_subnet.abcloud_Public_subnet_1.id

  tags = {
    Name = "website_nat_gateway_1"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.abcloud]
}

#nat_gateway_2
resource "aws_nat_gateway" "abcloud_nat_gateway_2" {
  connectivity_type = "private"
  #allocation_id = aws_eip.abcloud_eip_2.id
  subnet_id     = aws_subnet.abcloud_Public_subnet_2.id

  tags = {
    Name = "website_nat_gateway_2"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.abcloud]
}

#################################################################################
# ABCloud route table ==> four for each subnet
#################################################################################

#route_table_1
resource "aws_route_table" "abcloud_route_table_1" {
  vpc_id = aws_vpc.abcloud.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.abcloud.id
  }

  tags = {
    Name = "website_route_table_public_subnet_1"
  }
}

#association_route_table_1_to_public-subnet_1
resource "aws_route_table_association" "abcloud_route_table_1_public_subnet_1" {
  subnet_id      = aws_subnet.abcloud_Public_subnet_1.id
  route_table_id = aws_route_table.abcloud_route_table_1.id
}

#route_table_2
resource "aws_route_table" "abcloud_route_table_2" {
  vpc_id = aws_vpc.abcloud.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.abcloud.id
  }

  tags = {
    Name = "website_route_table_public_subnet_2"
  }
}

#association_route_table_2_to_public-subnet_2
resource "aws_route_table_association" "abcloud_route_table_2_public_subnet_2" {
  subnet_id      = aws_subnet.abcloud_Public_subnet_2.id
  route_table_id = aws_route_table.abcloud_route_table_2.id
}

#route_table_3
resource "aws_route_table" "abcloud_route_table_3" {
  vpc_id = aws_vpc.abcloud.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.abcloud_nat_gateway_1.id
  }

  tags = {
    Name = "website_route_table_private_subnet_1"
  }
}

#association_route_table_3_to_private-subnet_1
resource "aws_route_table_association" "abcloud_route_table_3_private_subnet_1" {
  subnet_id      = aws_subnet.abcloud_Private_subnet_1.id
  route_table_id = aws_route_table.abcloud_route_table_3.id
}

#route_table_4
resource "aws_route_table" "abcloud_route_table_4" {
  vpc_id = aws_vpc.abcloud.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.abcloud_nat_gateway_2.id
  }

  tags = {
    Name = "website_route_table_private_subnet_2"
  }
}

#association_route_table_4_to_private-subnet_2
resource "aws_route_table_association" "abcloud_route_table_4_private_subnet_2" {
  subnet_id      = aws_subnet.abcloud_Private_subnet_2.id
  route_table_id = aws_route_table.abcloud_route_table_4.id
}

