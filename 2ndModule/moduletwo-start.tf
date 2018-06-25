
#variables
variable "key_name" {
  default = "PYTHON"
}
variable "network_address_space" {
    default = "10.1.0.0/16"
}

variable "subnet1_address_space" {
    default = "10.1.0.0/24"
}

variable "subnet2_address_space" {
    default = "10.1.1.0/24"
}
################################################################################
provider "aws" {
   region = "us-east-1"
}

################################################################################
#DATA
################################################################################
data "aws_availability_zones" "available" {}

################################################################################
#Resources
################################################################################
#Networking

resource "aws_vpc" "vpc" {
  cidr_block = "${var.network_address_space}"
  enable_dns_hostnames = "true"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_subnet" "subnet1" {
  cidr_block = "${var.subnet1_address_space}"
  vpc_id     = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = "true"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_subnet" "subnet2" {
  cidr_block = "${var.subnet2_address_space}"
  vpc_id     = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = "true"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
}
################################################################################
#Routing
################################################################################

resource "aws_route_table" "rtb" {
  vpc_id = "${aws_vpc.vpc.id}"

  route = {
     cidr_block = "0.0.0.0/0"
     gateway_id = "${aws_internet_gateway.igw.id}"
  }
}

resource "aws_route_table_association" "rta-subnet1" {
  subnet_id = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_route_table_association" "rta-subnet2" {
  subnet_id = "${aws_subnet.subnet2.id}"
  route_table_id = "${aws_route_table.rtb.id}"
}

################################################################################
#Security Groups
################################################################################
#ELB Security Groups

resource  "aws_security_group" "elb-sg" {
  name = "elb_id"
  vpc_id = "${aws_vpc.vpc.id}"

#SSH access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
#Outbount traffic to internet
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#NGINX Security Groups

resource  "aws_security_group" "nginx-sg" {
  name = "nginx_id"
  vpc_id = "${aws_vpc.vpc.id}"

#SSH access from anywhere
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
#SSH access from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.network_address_space}"]
  }
#Outbount traffic to internet
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
################################################################################
#Load Balencer
################################################################################
resource "aws_elb" "nginx" {
  name = "nginx-elb"

  subnets = ["${aws_subnet.subnet1.id}", "${aws_subnet.subnet2.id}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]
  instances = ["${aws_instance.Nginx1.id}", "${aws_instance.Nginx2.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}


################################################################################
#Instance
################################################################################
resource "aws_instance" "Nginx1" {
   ami  = "ami-79cbe36f"
   instance_type = "t2.micro"
   key_name = "${var.key_name}"
   subnet_id = "${aws_subnet.subnet1.id}"
   vpc_security_group_ids = ["${aws_security_group.nginx-sg.id}"]
   associate_public_ip_address = true

   connection {
       user = "ubuntu"
       private_key = "${file("/Users/arunshetty/Downloads/PYTHON.pem")}"
   }

   provisioner "remote-exec" {
     inline = [
       "sudo apt-get update",
       "sudo apt-get install nginx -y",
       "sudo service nginx start"
     ]
   }
}

resource "aws_instance" "Nginx2" {
   ami  = "ami-79cbe36f"
   instance_type = "t2.micro"
   key_name = "${var.key_name}"
   subnet_id = "${aws_subnet.subnet2.id}"
   vpc_security_group_ids = ["${aws_security_group.nginx-sg.id}"]
   associate_public_ip_address = true

   connection {
       user = "ubuntu"
       private_key = "${file("/Users/arunshetty/Downloads/PYTHON.pem")}"
   }

   provisioner "remote-exec" {
     inline = [
       "sudo apt-get update",
       "sudo apt-get install nginx -y",
       "sudo service nginx start"
     ]
   }
}
################################################################################
#output
################################################################################
output "aws_instance_public_dns" {
    value = "${aws_instance.Nginx1.public_dns}"
}

output "aws_elb_public_dns" {
    value = "${aws_elb.nginx.dns_name}"
}
