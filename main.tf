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
# define sg
resource "aws_security_group" "tf-sg" {
    vpc_id = aws_vpc.tf-vpc.id
    name = "${var.project_name}-sg"
    #incoming rule
    ingress {
        description = "allow ssh"
        to_port = 22
        from_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "allow http"
        to_port = 80
        from_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "allow mysql"
        to_port = 3306
        from_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    #define outgoing
    egress {
        description = "allow any traffic"
        to_port = 0
        from_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    depends_on = [ aws_vpc.tf-vpc ]
}
# define app server in private subnet
resource "aws_instance" "tf-app-server" {
    subnet_id = aws_subnet.tf-private-subnet.id
    availability_zone = var.az1
    ami = var.ami
    key_name = var.key
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.tf-sg.id]
    tags = {
      Name = "${var.project_name}-app"
    }
    depends_on = [ aws_security_group.tf-sg ]
}
# define web server in publuic subnet
resource "aws_instance" "tf-web-server" {
    subnet_id = aws_subnet.tf-public-subnet.id
    availability_zone = var.az2
    ami = var.ami
    key_name = var.key
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.tf-sg.id]
    tags = {
      Name = "${var.project_name}-web"
    }
    depends_on = [ aws_security_group.tf-sg ]
  
}