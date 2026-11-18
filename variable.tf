#define and assign variable
variable "vpc_cidr" {
    default = "10.0.0.0/16"
}
variable "private_sub_cidr" {
    default = "10.0.0.0/20"
  
}
variable "az1" {
    default = "us-east-1a"
  
}
# define public subnet variable
variable "vpc_cidr_public" {
    default = "10.0.16.0/20"
  
}
variable "az2" {
    default = "us-east-1b"
  
}
variable "project_name" {
    default = "TCS"
  
}
variable "IGW_cidr" {
    default = "0.0.0.0/0"
  
}
variable "ami" {
    default = "ami-00f43ee0e98d52529"
  
}
variable "key" {
    default = "Pratik_45"
  
}
variable "instance_type" {
  default = "t3.micro"
}