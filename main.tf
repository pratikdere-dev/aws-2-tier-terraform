# define remote backend
terraform {
  backend "s3" {
    bucket = "devops-18-backend"
    key = "terraform.tfstate"
    region = "us-east-1"
    
  }
}
# define provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "tf-vpc" {
    cidr_block = var.vpc_cidr
    tags = {
        Name = "TCS_vpc"

    }
}
#define private subnet
resource "aws_subnet" "tf-private-subnet" {
    vpc_id = aws_vpc.tf-vpc.id
    cidr_block = var.private_sub_cidr
    availability_zone = var.az1
    tags = {
      Name = "${var.project_name}-private_subnet"
    }
  
}
#define public subnet
resource "aws_subnet" "tf-public-subnet" {
    vpc_id = aws_vpc.tf-vpc.id
    cidr_block = var.vpc_cidr_public
    availability_zone = var.az2
    map_public_ip_on_launch = true # auto assign ip enable
    tags = {
      Name = "${var.project_name}-public subnet"
    }
  
}
# define internet gateway
resource "aws_internet_gateway" "tf-IGW" {
    vpc_id = aws_vpc.tf-vpc.id
    tags = {
      Name = "${var.project_name}-IGW"
    }
  
}
#use existing route table which is created by vpc
resource "aws_default_route_table" "tf-main-RT" {
    default_route_table_id = aws_vpc.tf-vpc.default_route_table_id
    tags = {
        Name = "${var.project_name}-main-RT"

    }
  
}
#define routes in main-Rt
resource "aws_route" "tf-route" {
    route_table_id = aws_vpc.tf-vpc.default_route_table_id
    destination_cidr_block = var.IGW_cidr
    gateway_id = aws_internet_gateway.tf-IGW.id
  
}
# define web sg
resource "aws_security_group" "tf-web-sg" {

  name   = "${var.project_name}-web-sg"
  vpc_id = aws_vpc.tf-vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}
# define app security
resource "aws_security_group" "tf-app-sg" {

  name   = "${var.project_name}-app-sg"
  vpc_id = aws_vpc.tf-vpc.id

  ingress {
    description     = "Allow traffic from Web Server"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.tf-web-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}
# define db security
resource "aws_security_group" "tf-db-sg" {

  name   = "${var.project_name}-db-sg"
  vpc_id = aws_vpc.tf-vpc.id

  ingress {
    description     = "Allow MySQL from App Server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.tf-app-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# define app server in private subnet
resource "aws_instance" "tf-app-server" {
    subnet_id = aws_subnet.tf-private-subnet.id
    availability_zone = var.az1
    ami = var.ami
    key_name = var.key
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.tf-app-sg.id]
    tags = {
      Name = "${var.project_name}-app"
    }
    
}
# define web server in publuic subnet
resource "aws_instance" "tf-web-server" {
    subnet_id = aws_subnet.tf-public-subnet.id
    availability_zone = var.az2
    ami = var.ami
    key_name = var.key
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.tf-web-sg.id]
    tags = {
      Name = "${var.project_name}-web"
    }

  
}

# create a db subnet 
resource "aws_subnet" "tf-db-subnet" {
    vpc_id = aws_vpc.tf-vpc.id
    cidr_block = var.db_sub_cidr
    availability_zone = var.az3
    tags = {
      Name = "${var.project_name}-db-subnet"
    }
  
}
# create public route table 
resource "aws_route_table" "tf-public-RT" {
    vpc_id = aws_vpc.tf-vpc.id
    tags = {
      Name = "${var.project_name}-pub-RT"
    }
  
}
# internet gateway 
resource "aws_route" "tf-public-route" {

  route_table_id = aws_route_table.tf-public-RT.id

  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.tf-IGW.id
}
# associate with public subnet 
resource "aws_route_table_association" "tf-public-association" {
    subnet_id = aws_subnet.tf-public-subnet.id
    route_table_id = aws_route_table.tf-public-RT.id
  
}
# create private route  table
resource "aws_route_table" "tf-private-RT" {

  vpc_id = aws_vpc.tf-vpc.id

  tags = {
    Name = "${var.project_name}-private-RT"
  }
}
# associate db and app serever 
resource "aws_route_table_association" "tf-app-association" {
    subnet_id = aws_subnet.tf-private-subnet.id
    route_table_id = aws_route_table.tf-private-RT.id
  
}
resource "aws_route_table_association" "tf-db-association" {
    subnet_id = aws_subnet.tf-db-subnet.id
    route_table_id = aws_route_table.tf-private-RT.id
  
}
# create db server
# Database EC2 Server

resource "aws_instance" "tf-db-server" {

  ami = var.ami

  instance_type = var.instance_type

  subnet_id = aws_subnet.tf-db-subnet.id

  availability_zone = var.az3

  key_name = var.key

  vpc_security_group_ids = [
    aws_security_group.tf-db-sg.id
  ]

  tags = {
    Name = "${var.project_name}-db-server"
  }
}
# create elastic ip for NAT gateway
resource "aws_eip" "tf-nat-eip" {
    domain = "vpc"
    tags = {
      Name = "${var.project_name}-nat-eip"
    }
  
}
# create nat gateway
resource "aws_nat_gateway" "tf-nat" {
    allocation_id = aws_eip.tf-nat-eip.id
    subnet_id = aws_subnet.tf-public-subnet.id
    tags = {
      Name = "${var.project_name}-NAT-gateway"

    }
    depends_on = [ aws_internet_gateway.tf-IGW ]
}
#  private route through nat gateway
resource "aws_route" "tf-private-route" {
    route_table_id = aws_route_table.tf-private-RT.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.tf-nat.id

  
}