provider "aws" {
	region = "${var.aws_region}"
}

#terraform {
#  backend "s3" {
#    bucket         = "shsca5-tfsharedstate"
#    key            = "global/s3/terraform.tfstate"
#    region         = "ca-central-1"
#    dynamodb_table = "shsca5-tflocks"
#    encrypt        = true
#  }
#}

# EC2 key pair
resource "aws_key_pair" "maz" {
	key_name = "kp${var.maz_name}"
	public_key = "${file(var.key_path)}"
}

# AMI
data "aws_ami" "ubuntu" {
	most_recent = true
	filter {
		name = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
	}
	filter {
		name = "virtualization-type"
		values = ["hvm"]
	}
	owners = ["099720109477"] #Canonical
}

# Instance
resource "aws_instance" "bastionHost" {
	ami = "${data.aws_ami.ubuntu.id}"
	instance_type = "t2.micro"
	key_name = "${aws_key_pair.maz.id}"
	subnet_id = "${aws_subnet.maz_int1.id}"
	vpc_security_group_ids = ["${aws_security_group.maz_int.id}"]
	associate_public_ip_address = true
	source_dest_check = false
	# user_data = "${file("install.sh")}"
	user_data = <<-EOF
		# Core dependencies
		sudo apt-get update
		curl -fsSL https://get.docker.com | sh
		sudo usermod -aG docker $USER
		newgrp docker
		#
		# Bastion Host
		echo "${var.uname}:${var.upassword}:Y" > /root/createusers.txt
		docker run --restart unless-stopped -p 2222:22 -p 3389:3389 -v /root/createusers.txt -v /home -dit rattydave/docker-ubuntu-xrdp-mate-custom:19.10
	EOF

	tags = {
		Name = "inBastionHost${count.index}"
		f5sd = "pool_BastionHost"
		f5rg = "${var.tag_name}"
		tenant = "${var.maz_name} "
	}
	count = 1
}
