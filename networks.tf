# Security VPC Networks
# VPC
resource "aws_vpc" "main" {
	cidr_block = "${var.security_vpc_cidr}"
	assign_generated_ipv6_cidr_block = true
	enable_dns_support = true
	enable_dns_hostnames = true
	tags = {
		Name = "vpc${var.tag_name}"
	}
}

# Management subnet in AZ1
resource "aws_subnet" "az1_mgmt" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_security_subnets.mgmt
	tags = {
		Name = "snetAz1Mgmt"
	}
}

# Management subnet in AZ2
resource "aws_subnet" "az2_mgmt" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_security_subnets.mgmt
	tags = {
		Name = "snetAz2Mgmt"
	}
}

# External subnet in AZ1
resource "aws_subnet" "az1_ext" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_security_subnets.paz_ext
	tags = {
		Name = "snetAz1External"
	}
}

# External subnet in AZ2
resource "aws_subnet" "az2_ext" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_security_subnets.paz_ext
	tags = {
		Name = "snetAz2External"
	}
}

# DMZ External subnet in AZ1
resource "aws_subnet" "az1_dmzExt" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_security_subnets.dmz_ext
	tags = {
		Name = "snetAz1DmzExt"
	}
}

# DMZ External subnet in AZ2
resource "aws_subnet" "az2_dmzExt" {
	vpc_id = "${aws_vpc.main.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_security_subnets.dmz_ext
	tags = {
		Name = "snetAz2DmzExt"
	}
}

# DMZ Internal subnet in AZ1
resource "aws_subnet" "az1_dmzInt" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_security_subnets.dmz_int
	tags = {
		Name = "snetAz2DmzInt"
	}
}

# DMZ Internal subnet in AZ2
resource "aws_subnet" "az2_dmzInt" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_security_subnets.dmz_int
	tags = {
		Name = "snetAz2DmzInt"
	}
}

# DMZ External subnet in AZ1
resource "aws_subnet" "az1_transit" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_security_subnets.transit
	tags = {
		Name = "snetAz1Transit"
	}
}

# DMZ External subnet in AZ2
resource "aws_subnet" "az2_transit" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_security_subnets.transit
	tags = {
		Name = "snetAz2Transit"
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
    depends_on         = [aws_subnet.az1_transit, aws_subnet.az2_transit]
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
    depends_on         = [aws_ec2_transit_gateway.hubtgw]
  	subnet_ids         = [var.az1_security_subnets.transit, var.az2_security_subnets.transit]
  	transit_gateway_id = aws_ec2_transit_gateway.hubtgw.id
  	vpc_id             = aws_vpc.main.id

  	tags = {
		Name = "${var.tag_name}-hubTgwAttach"
  	}
}

# TGW Route Table
resource "aws_ec2_transit_gateway_route_table" "hubtgwRt" {
  depends_on         = [aws_ec2_transit_gateway.hubtgw]
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

resource "aws_route_table" "TransitRt" {
	vpc_id = "${aws_vpc.main.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gw.id}"
	}
	route {
		cidr_block = "${var.tenant_vpc_cidr}"
		transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
	}
	route {
		cidr_block = "${var.ztsra_vpc_cidr}"
		transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
	}
	tags = {
		Name = "TransitRT"
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
resource "aws_route_table_association" "az1_mgmt" {
	subnet_id = "${aws_subnet.az1_mgmt.id}"
	route_table_id = "${aws_route_table.MgmtRt.id}"
}

# Assign route table to management subnet in AZ2
resource "aws_route_table_association" "az2_mgmt" {
	subnet_id = "${aws_subnet.az2_mgmt.id}"
	route_table_id = "${aws_route_table.MgmtRt.id}"
}

# Assign route table to PAZ external subnet in AZ1
resource "aws_route_table_association" "az1_ext" {
	subnet_id = "${aws_subnet.az1_ext.id}"
	route_table_id = "${aws_route_table.PazRt.id}"
}

# Assign route table to PAZ external subnet in AZ2
resource "aws_route_table_association" "az2_ext" {
	subnet_id = "${aws_subnet.az2_ext.id}"
	route_table_id = "${aws_route_table.PazRt.id}"
}

# Assign route table to DMZ external subnet in AZ1
resource "aws_route_table_association" "az1_dmzExt" {
	subnet_id = "${aws_subnet.az1_dmzExt.id}"
	route_table_id = "${aws_route_table.DmzExtRt.id}"
}

# Assign route table to DMZ external subnet in AZ2
resource "aws_route_table_association" "az2_dmzExt" {
	subnet_id = "${aws_subnet.az2_dmzExt.id}"
	route_table_id = "${aws_route_table.DmzExtRt.id}"
}

# Assign route table to DMZ Internal subnet in AZ1
resource "aws_route_table_association" "az1_dmzInt" {
	subnet_id = "${aws_subnet.az1_dmzInt.id}"
	route_table_id = "${aws_route_table.DmzIntRt.id}"
}

# Assign route table to DMZ Internal subnet in AZ2
resource "aws_route_table_association" "az2_dmzInt" {
	subnet_id = "${aws_subnet.az2_dmzInt.id}"
	route_table_id = "${aws_route_table.DmzIntRt.id}"
}

# Assign route table to Transit subnet in AZ1
resource "aws_route_table_association" "az1_transit" {
	subnet_id = "${aws_subnet.az1_transit.id}"
	route_table_id = "${aws_route_table.TransitRt.id}"
}

# Assign route table to Transit subnet in AZ2
resource "aws_route_table_association" "az2_transit" {
	subnet_id = "${aws_subnet.az2_transit.id}"
	route_table_id = "${aws_route_table.TransitRt.id}"
}
