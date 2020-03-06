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

# Instances
resource "aws_instance" "az1_bastionHost" {
	depends_on = [aws_subnet.az1_tenant_int]
	ami = data.aws_ami.ubuntu.id
	instance_type = "t2.micro"
	key_name = aws_key_pair.tenant.id
	subnet_id = aws_subnet.az1_tenant_int.id
	vpc_security_group_ids = [aws_security_group.sg_internal.id]
	associate_public_ip_address = true
	source_dest_check = false
	# user_data = "${file("install.sh")}"
	user_data = <<-EOF
		# Core dependencies
		apt-get -y update
		apt-get -y upgrade
		apt-get -y install docker.io
		#
		# Bastion Host
		docker run -dit --restart unless-stopped --shm-size 1g --name rdp -p 3389:3389 danielguerra/alpine-xfce4-xrdp
		docker run --restart unless-stopped -p 80:80 -dit bkimminich/juice-shop
	EOF

	tags = {
		Name = "${var.prefix}-${var.tenant_name}-az1_BastionHost${count.index}"
		f5sd = "pool_BastionHost"
		f5rg = var.prefix
		tenant = var.tenant_name
	}
	count = 1
}

resource "aws_instance" "az2_bastionHost" {
	depends_on = [aws_subnet.az2_tenant_int]
	ami = data.aws_ami.ubuntu.id
	instance_type = "t2.micro"
	key_name = aws_key_pair.tenant.id
	subnet_id = aws_subnet.az2_tenant_int.id
	vpc_security_group_ids = [aws_security_group.sg_internal.id]
	associate_public_ip_address = true
	source_dest_check = false
	# user_data = "${file("install.sh")}"
	user_data = <<-EOF
		# Core dependencies
		apt-get -y update
		apt-get -y upgrade
		apt-get -y install docker.io
		#
		# Bastion Host
		docker run -dit --restart unless-stopped --shm-size 1g --name rdp -p 3389:3389 danielguerra/alpine-xfce4-xrdp
	EOF

	tags = {
		Name = "${var.prefix}-${var.tenant_name}-az2_BastionHost${count.index}"
		f5sd = "pool_BastionHost"
		f5rg = var.prefix
		tenant = var.tenant_name
	}
	count = 1
}

# Instances
resource "aws_instance" "az1_juiceShopHost" {
	depends_on = [aws_subnet.az1_tenant_int]
	ami = data.aws_ami.ubuntu.id
	instance_type = "t2.micro"
	key_name = aws_key_pair.tenant.id
	subnet_id = aws_subnet.az1_tenant_int.id
	vpc_security_group_ids = [aws_security_group.sg_internal.id]
	associate_public_ip_address = true
	source_dest_check = false
	# user_data = "${file("install.sh")}"
	user_data = <<-EOF
		# Core dependencies
		apt-get -y update
		apt-get -y upgrade
		apt-get -y install docker.io
		# docker workload
		docker run -dit --restart unless-stopped --name juiceShop -p 80:80 bkimminich/juice-shop
	EOF

	tags = {
		Name = "${var.prefix}-${var.tenant_name}-az1_juiceShopHost${count.index}"
		f5sd = "pool_opencart"
		f5rg = var.prefix
		tenant = var.tenant_name
	}
	count = 1
}

resource "aws_instance" "az2_juiceShopHost" {
	depends_on = [aws_subnet.az2_tenant_int]
	ami = data.aws_ami.ubuntu.id
	instance_type = "t2.micro"
	key_name = aws_key_pair.tenant.id
	subnet_id = aws_subnet.az2_tenant_int.id
	vpc_security_group_ids = [aws_security_group.sg_internal.id]
	associate_public_ip_address = true
	source_dest_check = false
	# user_data = "${file("install.sh")}"
	user_data = <<-EOF
		# Core dependencies
		apt-get -y update
		apt-get -y upgrade
		apt-get -y install docker.io
		# docker workload
		docker run -dit --restart unless-stopped --name juiceShop -p 80:3000 bkimminich/juice-shop
	EOF

	tags = {
		Name = "${var.prefix}-${var.tenant_name}-az2_juiceShopHost${count.index}"
		f5sd = "pool_opencart"
		f5rg = var.prefix
		tenant = var.tenant_name
	}
	count = 1
}
