#variables

#variable "aws_access_key" {}
#variable "aws_secret_key" {}
#variable "private_key_my" {}
#variable "security_groups" {type="list"}
variable "key_name" {
  default = "PYTHON"
}

#Providers

provider "aws" {
#   access_key = "${aws_access_key}"
#   secret_key = "${var.aws_secret_key}"
   region = "us-east-1"
}

#Resources

resource "aws_instance" "Ubuntu_terraform" {
   ami  = "ami-79cbe36f"
   instance_type = "t2.micro"
   key_name = "${var.key_name}"
   subnet_id = "subnet-4b6b6613"
#   security_groups = ["${var.security_groups}"]
   vpc_security_group_ids = ["sg-8e1a70ff"]
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

#output

output "aws_instance_public_dns" {
    value = "${aws_instance.Ubuntu_terraform.public_dns}"
}
