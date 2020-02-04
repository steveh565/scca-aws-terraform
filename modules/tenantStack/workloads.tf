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
resource "aws_instance" "az1_bastionHost" {
	depends_on = [aws_subnet.az1_tenant_int]
	ami = "${data.aws_ami.ubuntu.id}"
	instance_type = "t2.micro"
	key_name = "${aws_key_pair.tenant.id}"
	subnet_id = aws_subnet.az1_tenant_int.id
	vpc_security_group_ids = ["${aws_security_group.tenant_sg_internal.id}"]
	associate_public_ip_address = true
	source_dest_check = false
	# user_data = "${file("install.sh")}"
	user_data = <<-EOF
		# Core dependencies
		sudo apt-get update
		sudo apt-get -y install docker.io
		#
		# Bastion Host
		sudo docker run -dit --restart unless-stopped --shm-size 1g --name rdp -p 3389:3389 danielguerra/alpine-xfce4-xrdp
		sudo docker run --privileged=true --restart unless-stopped -p 80:80 -dit vulnerables/web-dvwa:latest
	EOF

	tags = {
		Name = "az1_BastionHost${count.index}"
		f5sd = "pool_BastionHost"
		f5rg = "${var.tag_name}"
		tenant = "${var.tenant_name} "
	}
	count = 1
}

resource "aws_instance" "az2_bastionHost" {
	depends_on = [aws_subnet.az2_tenant_int]
	ami = "${data.aws_ami.ubuntu.id}"
	instance_type = "t2.micro"
	key_name = "${aws_key_pair.tenant.id}"
	subnet_id = aws_subnet.az2_tenant_int.id
	vpc_security_group_ids = ["${aws_security_group.sg_internal.id}"]
	associate_public_ip_address = true
	source_dest_check = false
	# user_data = "${file("install.sh")}"
	user_data = <<-EOF
		# Core dependencies
		sudo apt-get update
		sudo apt-get -y install docker.io
		#
		# Bastion Host
		sudo docker run -dit --restart unless-stopped --shm-size 1g --name rdp -p 3389:3389 danielguerra/alpine-xfce4-xrdp
		sudo docker run --privileged=true --restart unless-stopped -p 80:80 -dit vulnerables/web-dvwa:latest
	EOF

	tags = {
		Name = "az2_BastionHost${count.index}"
		f5sd = "pool_BastionHost"
		f5rg = "${var.tag_name}"
		tenant = "${var.tenant_name} "
	}
	count = 1
}
