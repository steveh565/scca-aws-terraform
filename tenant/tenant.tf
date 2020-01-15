provider "aws" {
	region = "${var.aws_region}"
}

# EC2 key pair
resource "aws_key_pair" "tenant" {
	key_name = "kp${var.tenant_name}"
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
resource "aws_instance" "HttpsWorkload" {
	ami = "${data.aws_ami.ubuntu.id}"
	instance_type = "t2.micro"
	key_name = "${aws_key_pair.tenant.id}"
	subnet_id = "${aws_subnet.tenant_int1.id}"
	vpc_security_group_ids = ["${aws_security_group.tenant_int.id}"]
	associate_public_ip_address = true
	source_dest_check = false
	user_data = "${file("install.sh")}"
	tags = {
		Name = "inHttpsWorkload${count.index}"
		f5sd = "pool_HttpsWorkload"
		f5rg = "${var.tag_name}"
		tenant = "${var.tenant_name} "
	}
	count = 2
}
