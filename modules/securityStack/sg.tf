# External security group
resource "aws_security_group" "sg_external" {
	name = var.sgExternal
	description = "HTTP/S access"
	ingress {
		protocol = "tcp"
		from_port = 80
		to_port = 80
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		protocol = "tcp"
		from_port = 443
		to_port = 443
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress { 
		protocol = "tcp"
		from_port = 4353
		to_port = 4353
		cidr_blocks = [var.security_vpc_cidr]
	}
	ingress { 
		protocol = "udp"
		from_port = 1026
		to_port = 1026
		cidr_blocks = [var.security_vpc_cidr]
	}
	ingress {
		protocol = "icmp"
		from_port = -1
		to_port = -1
		cidr_blocks = [var.security_vpc_cidr]
	}
	egress {
		protocol = -1
		from_port = 0
		to_port = 0
		cidr_blocks = ["0.0.0.0/0"]
	}
	vpc_id = aws_vpc.main.id
	tags = {
		Name = var.sgExternal
		f5rg = "${var.tag_name}"
	}
}

# External Mgmt security group
resource "aws_security_group" "sg_ext_mgmt" {
	name = var.sgExtMgmt
	ingress {
		protocol = "tcp"
		from_port = 22
		to_port = 22
		cidr_blocks = ["${var.mgmt_asrc[0]}"]
	}
	ingress {
		protocol = "tcp"
		from_port = 443
		to_port = 443
		cidr_blocks = ["${var.mgmt_asrc[0]}"]
	}
	ingress {
		protocol = "icmp"
		from_port = -1
		to_port = -1
		cidr_blocks = [var.security_vpc_cidr]
	}
	egress {
		protocol = -1
		from_port = 0
		to_port = 0
		cidr_blocks = ["0.0.0.0/0"]
	}
	vpc_id = aws_vpc.main.id
	tags = {
		Name = var.sgExtMgmt
		f5rg = "${var.tag_name}"
	}
}


# Internal security group
resource "aws_security_group" "sg_internal" {
	name = var.sgInternal
	description = "wide open"
	ingress {
		protocol = -1
		from_port = 0
		to_port = 0
		cidr_blocks = ["0.0.0.0/0"]
	}
	egress {
		protocol = -1
		from_port = 0
		to_port = 0
		cidr_blocks = ["0.0.0.0/0"]
	}
	vpc_id = aws_vpc.main.id
	tags = {
		Name = var.sgInternal
		f5rg = "${var.tag_name}"
	}
}
