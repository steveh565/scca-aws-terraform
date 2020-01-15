# Infrastructure
provider "aws" {
	region = "${var.aws_region}"
}

# VPC
resource "aws_vpc" "main" {
	cidr_block = "${var.vpc_cidr}"
	assign_generated_ipv6_cidr_block = true
	enable_dns_support = true
	enable_dns_hostnames = true
	tags = {
		Name = "vpc${var.tag_name}"
	}
}

# Management subnet in AZ1
resource "aws_subnet" "mgmt1" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = "${var.mgmt1_cidr}"
	tags = {
		Name = "snetMgmt1"
	}
}

# Management subnet in AZ2
resource "aws_subnet" "mgmt2" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = "${var.mgmt2_cidr}"
	tags = {
		Name = "snetMgmt2"
	}
}

# External subnet in AZ1
resource "aws_subnet" "ext1" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = "${var.ext1_cidr}"
	tags = {
		Name = "snetExternal1"
	}
}

# External subnet in AZ2
resource "aws_subnet" "ext2" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = "${var.ext2_cidr}"
	tags = {
		Name = "snetExternal2"
	}
}

# DMZ External subnet in AZ1
resource "aws_subnet" "dmzExt1" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = "${var.dmzExt1_cidr}"
	tags = {
		Name = "snetDmzExt1"
	}
}

# DMZ External subnet in AZ2
resource "aws_subnet" "dmzExt2" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = "${var.dmzExt2_cidr}"
	tags = {
		Name = "snetDmzExt2"
	}
}

# DMZ External subnet in AZ1
resource "aws_subnet" "dmzInt1" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = "${var.dmzInt1_cidr}"
	tags = {
		Name = "snetDmzInt1"
	}
}

# DMZ External subnet in AZ2
resource "aws_subnet" "dmzInt2" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = "${var.dmzInt2_cidr}"
	tags = {
		Name = "snetDmzInt2"
	}
}

# DMZ External subnet in AZ1
resource "aws_subnet" "trustedInt1" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = "${var.trustedInt1_cidr}"
	tags = {
		Name = "snetTrustedInt1"
	}
}

# DMZ External subnet in AZ2
resource "aws_subnet" "trustedInt2" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = "${var.trustedInt2_cidr}"
	tags = {
		Name = "snetTrustedInt2"
	}
}

# Internet gateway
resource "aws_internet_gateway" "gw" {
	vpc_id = "${aws_vpc.main.id}"
	tags = {
		Name = "igw${var.tag_name}"
	}
}

# Hub Transit Gateway
resource "aws_ec2_transit_gateway" "hubtgw" {
	auto_accept_shared_attachments = "enable"
	default_route_table_propagation = "enable"
	default_route_table_association = "enable"
	dns_support = "enable"
	vpn_ecmp_support = "enable"
	tags = {
		Name = "${var.vpc_tgw_name}"
	}
}

# Transit Gateway Attach
resource "aws_ec2_transit_gateway_vpc_attachment" "hubTgwAttach" {
  	subnet_ids         = ["${aws_subnet.trustedInt1.id}", "${aws_subnet.trustedInt2.id}"]
  	transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
  	vpc_id             = "${aws_vpc.main.id}"

  	tags = {
		Name = "${var.tag_name}-hubTgwAttach"
		Tenant = "${var.tag_name}"
  	}
}

# TGW Route Table
resource "aws_ec2_transit_gateway_route_table" "hubtgwRt" {
  transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
	tags = {
		Name = "${var.vpc_tgw_name}-RouteTable"
	}
}

# Route tables
resource "aws_route_table" "publicRt" {
	vpc_id = "${aws_vpc.main.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gw.id}"
	}
	tags = {
		Name = "rtPublic"
	}
}

resource "aws_route_table" "EdgeRt" {
	vpc_id = "${aws_vpc.main.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gw.id}"
	}
	tags = {
		Name = "EdgeRT"
	}
}

resource "aws_route_table" "PazRt" {
	vpc_id = "${aws_vpc.main.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gw.id}"
	}
	tags = {
		Name = "PazRT"
	}
}

resource "aws_route_table" "DmzExtRt" {
	vpc_id = "${aws_vpc.main.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gw.id}"
	}
	tags = {
		Name = "DmzExtRT"
	}
}

resource "aws_route_table" "DmzIntRt" {
	vpc_id = "${aws_vpc.main.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gw.id}"
	}
	tags = {
		Name = "DmzIntRT"
	}
}

resource "aws_route_table" "TrustedIntRt" {
	vpc_id = "${aws_vpc.main.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gw.id}"
	}
	tags = {
		Name = "TrustedIntRT"
	}
}

resource "aws_route_table" "MgmtRt" {
	vpc_id = "${aws_vpc.main.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gw.id}"
	}
	tags = {
		Name = "MgmtRT"
	}
}

# Assign route table to management subnet in AZ1
resource "aws_route_table_association" "mgmt1" {
	subnet_id = "${aws_subnet.mgmt1.id}"
	route_table_id = "${aws_route_table.MgmtRt.id}"
}

# Assign route table to management subnet in AZ2
resource "aws_route_table_association" "mgmt2" {
	subnet_id = "${aws_subnet.mgmt2.id}"
	route_table_id = "${aws_route_table.MgmtRt.id}"
}

# Assign route table to PAZ external subnet in AZ1
resource "aws_route_table_association" "ext1" {
	subnet_id = "${aws_subnet.ext1.id}"
	route_table_id = "${aws_route_table.PazRt.id}"
}

# Assign route table to PAZ external subnet in AZ2
resource "aws_route_table_association" "ext2" {
	subnet_id = "${aws_subnet.ext2.id}"
	route_table_id = "${aws_route_table.PazRt.id}"
}

# Assign route table to DMZ external subnet in AZ1
resource "aws_route_table_association" "dmzExt1" {
	subnet_id = "${aws_subnet.dmzExt1.id}"
	route_table_id = "${aws_route_table.DmzExtRt.id}"
}

# Assign route table to DMZ external subnet in AZ2
resource "aws_route_table_association" "dmzExt2" {
	subnet_id = "${aws_subnet.dmzExt2.id}"
	route_table_id = "${aws_route_table.DmzExtRt.id}"
}

# Assign route table to DMZ Internal subnet in AZ1
resource "aws_route_table_association" "dmzInt1" {
	subnet_id = "${aws_subnet.dmzInt1.id}"
	route_table_id = "${aws_route_table.DmzIntRt.id}"
}

# Assign route table to DMZ Internal subnet in AZ2
resource "aws_route_table_association" "dmzInt2" {
	subnet_id = "${aws_subnet.dmzInt2.id}"
	route_table_id = "${aws_route_table.DmzIntRt.id}"
}

# Assign route table to Trusted Internal subnet in AZ1
resource "aws_route_table_association" "trustedInt1" {
	subnet_id = "${aws_subnet.trustedInt1.id}"
	route_table_id = "${aws_route_table.TrustedIntRt.id}"
}

# Assign route table to Trusted Internal subnet in AZ2
resource "aws_route_table_association" "trustedInt2" {
	subnet_id = "${aws_subnet.trustedInt2.id}"
	route_table_id = "${aws_route_table.TrustedIntRt.id}"
}



output "Hub_Transit_Gateway_ID" { value = "${aws_ec2_transit_gateway.hubtgw.id}" }

output "MAZ_Portal_Local_VIP" { value = "NULL" }
output "MAZ_Portal_EIP" { value = "NULL" }

output "Tenant-1_Workload_Local_VIP" { value = "NULL" }
output "Tenant-1_Workload_EIP" { value = "NULL" }