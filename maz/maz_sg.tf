# MAZ Internal security group
resource "aws_security_group" "maz_int" {
	name = "sgInternal"
	description = "SSH, HTTP/S, WS and ICMP access"
	ingress {
		protocol = "tcp"
		from_port = 22
		to_port = 22
		cidr_blocks = "${var.mgmt_asrc}"
	}
	ingress {
		protocol = "tcp"
		from_port = 3389
		to_port = 3389
		cidr_blocks = "${var.mgmt_asrc}"
	}
	ingress {
		protocol = "tcp"
		from_port = 80
		to_port = 80
		cidr_blocks = ["${var.maz_vpc_cidr}"]
	}
	ingress {
		protocol = "tcp"
		from_port = 443
		to_port = 443
		cidr_blocks = ["${var.maz_vpc_cidr}"]
	}
	ingress {
		protocol = "tcp"
		from_port = 4433
		to_port = 4433
		cidr_blocks = ["${var.maz_vpc_cidr}"]
	}
	ingress {
		protocol = "icmp"
		from_port = -1
		to_port = -1
		cidr_blocks = ["${var.maz_vpc_cidr}"]
	}
	egress {
		protocol = -1
		from_port = 0
		to_port = 0
		cidr_blocks = ["0.0.0.0/0"]
	}
	vpc_id = "${aws_vpc.maz.id}"
	tags = {
		Name = "sg${var.maz_name}-Internal"
		f5rg = "${var.tag_name}"
        Tenant = "${var.maz_name}"
	}
}

# Assign route table to internal subnet
resource "aws_route_table_association" "maz_int1" {
	subnet_id = "${aws_subnet.maz_int1.id}"
	route_table_id = "${aws_route_table.maz.id}"
}

# Assign route table to internal subnet
resource "aws_route_table_association" "maz_int2" {
	subnet_id = "${aws_subnet.maz_int2.id}"
	route_table_id = "${aws_route_table.maz.id}"
}