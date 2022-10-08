
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
# ABCloud Subnet ==> 2 publics and 2 privates in 2 AZ for high availability
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

#################################################################################
# ABCloud ssh key pair
#################################################################################

# Generate SSH key to connect the ec2 instances
resource "tls_private_key" "abcloud_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Stores the public key in aws
resource "aws_key_pair" "abcloud_ssh_public_key" {
  key_name   = "abcloud_key_pair"
  public_key = tls_private_key.abcloud_ssh_key.public_key_openssh
}

# Stores the private key in the local system
resource "local_file" "abcloud_ssh_private_key" {
    content  = tls_private_key.abcloud_ssh_key.private_key_pem
    filename = "abcloud_key_pair"
}

#################################################################################
# ABCloud security group ==> one for ec2 & one for data base
#################################################################################

# creating security to control ec2 access
resource "aws_security_group" "abcloud_security_group" {
  name        = "allow_website"
  description = "Allow website inbound traffic"
  vpc_id      = aws_vpc.abcloud.id

  tags = {
    Name = "abcloud_security_group"
  }
}

# setting security rule for ssh inbound
resource "aws_security_group_rule" "abcloud_ssh_inbound" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.abcloud_security_group.id
}

# setting security rule for http inbound
resource "aws_security_group_rule" "abcloud_http_inbound" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.abcloud_security_group.id
}

# setting security rule for all outbound
resource "aws_security_group_rule" "abcloud_outbound_connection" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.abcloud_security_group.id
}

# creating security group to control data base access
resource "aws_security_group" "abcloud_db_security_group" {
  name        = "allow_data_base"
  description = "Allow data base connection"
  vpc_id      = aws_vpc.abcloud.id

  tags = {
    Name = "abcloud_db_security_group"
  }
}

# setting security rule for vpc inbound
resource "aws_security_group_rule" "abcloud_vpc_inbound" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"]
  security_group_id = aws_security_group.abcloud_db_security_group.id
}

#################################################################################
# ABCloud EC2 instance ==> for high availability one in each public subnet/AZ
#################################################################################

# ec2_public_server_1
resource "aws_instance" "abcloud_public_server_1" {
  ami           		= "ami-02d0b1ffa5f16402d"
  instance_type 		= "t2.micro"
  #vpc_id 			= aws_vpc.abcloud.id
  subnet_id			= aws_subnet.abcloud_Public_subnet_1.id
  associate_public_ip_address	= true
  vpc_security_group_ids	= [aws_security_group.abcloud_security_group.id]
  key_name			= "abcloud_key_pair"
  
  tags = {
    Name = "abcloud_public_server_1"
  }
}

#################################################################################
# ABCloud data base ==> for high availability it should be multi AZ
#################################################################################

resource "aws_db_subnet_group" "abcloud_db_subnet_group" {
  name       = "abcloud_db_subnet_group"
  subnet_ids = [aws_subnet.abcloud_Private_subnet_1.id, aws_subnet.abcloud_Private_subnet_2.id]
  tags = {
    Name = "abcloud"
  }
}

# data base 
resource "aws_db_instance" "abcloud_private_data_base" {
  identifier			= "abcloud-private-data-base"
  allocated_storage    	= 10
  engine               	= "postgres"
  engine_version       	= "14.2"
  instance_class       	= "db.t3.micro"
  availability_zone 		= "${local.region}a"
  db_subnet_group_name 	= aws_db_subnet_group.abcloud_db_subnet_group.name
  multi_az			= false
  publicly_accessible		= false
  #security_group_names 	= "allow_data_base"
  vpc_security_group_ids	= [aws_security_group.abcloud_db_security_group.id]
  name                 	= "abcloud_data_base"
  username             	= "abcloud"
  password             	= "abcloud123"
  parameter_group_name 	= "default.postgres14"
  skip_final_snapshot  	= true
}

#################################################################################
# ABCloud AutoScaling ==> autoscaling / lunchconfiguration / 
#################################################################################

# setting launch configuration
resource "aws_launch_configuration" "abcloud_launch_configuration" {
  name_prefix   = "abcloud_launch_configuration"
  image_id      = "ami-0be42a9300c01da54"
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}

# setting autoscalling group
resource "aws_autoscaling_group" "abcloud_autoscaling_group" {
  name                 = "abcloud_autoscaling_group"
  vpc_zone_identifier  = [aws_subnet.abcloud_Public_subnet_1.id, aws_subnet.abcloud_Public_subnet_2.id]
  desired_capacity     = 1
  min_size             = 1
  max_size             = 2

  launch_configuration = aws_launch_configuration.abcloud_launch_configuration.name
  
  #lifecycle {
  # create_before_destroy = true
  #}
}

#################################################################################
# ABCloud Load Balancer ==> loadbalancer / targetgroup / 
#################################################################################

# setting load balancer
resource "aws_lb" "abcloud_load_balancer" {
  name               = "abcloud-load-balancer"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.abcloud_security_group.id]
  subnets            = [aws_subnet.abcloud_Public_subnet_1.id, aws_subnet.abcloud_Public_subnet_2.id]
  internal           = false

  #enable_deletion_protection = true
}

# setting listener for load balancer
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.abcloud_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.abcloud_target_group.arn
  }
}

#setting taget group for load balancer
resource "aws_lb_target_group" "abcloud_target_group" {
  name     = "abcloud-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.abcloud.id
}

# attaching autoscalling with load balancer target group
resource "aws_autoscaling_attachment" "abcloud_attachement_autoscaling_load_balancer" {
  autoscaling_group_name = aws_autoscaling_group.abcloud_autoscaling_group.id
  lb_target_group_arn    = aws_lb_target_group.abcloud_target_group.arn
}


