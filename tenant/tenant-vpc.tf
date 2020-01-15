# VPC
resource "aws_vpc" "tenant" {
	cidr_block = "${var.tenant_vpc_cidr}"
	assign_generated_ipv6_cidr_block = true
	enable_dns_support = true
	enable_dns_hostnames = true
	tags = {
		Name = "vpc${var.tag_name}-${var.tenant_name}"
		Tenant = "${var.tenant_name}"
	}
}

# Management subnet in AZ1
resource "aws_subnet" "tenant_mgmt1" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = "${var.tenant_mgmt1_cidr}"
	tags = {
		Name = "${var.tenant_name}-snetMgmt1"
		Tenant = "${var.tenant_name}"
	}
}

# Management subnet in AZ2
resource "aws_subnet" "tenant_mgmt2" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = "${var.tenant_mgmt2_cidr}"
	tags = {
		Name = "${var.tenant_name}-snetMgmt2"
		Tenant = "${var.tenant_name}"
	}
}

# External subnet in AZ1
resource "aws_subnet" "tenant_ext1" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = "${var.tenant_ext1_cidr}"
	tags = {
		Name = "${var.tenant_name}-snetExternal1"
		Tenant = "${var.tenant_name}"
	}
}

# External subnet in AZ2
resource "aws_subnet" "tenant_ext2" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = "${var.tenant_ext2_cidr}"
	tags = {
		Name = "${var.tenant_name}-snetExternal2"
		Tenant = "${var.tenant_name}"
	}
}

# Internal subnet in AZ1
resource "aws_subnet" "tenant_int1" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = "${var.tenant_int1_cidr}"
	tags = {
		Name = "${var.tenant_name}-snetInternal1"
		Tenant = "${var.tenant_name}"
	}
}

# Internal subnet in AZ2
resource "aws_subnet" "tenant_int2" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = "${var.tenant_int2_cidr}"
	tags = {
		Name = "${var.tenant_name}-snetInternal2"
		Tenant = "${var.tenant_name}"
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
resource "aws_ec2_transit_gateway_vpc_attachment" "tenantTgwAttach" {
  	subnet_ids         = ["${aws_subnet.tenant_ext1.id}", "${aws_subnet.tenant_ext2.id}"]
  	transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
  	vpc_id             = "${aws_vpc.tenant.id}"

  	tags = {
		Name = "${var.tenant_name}-TgwAttach"
		Tenant = "${var.tenant_name}"
  	}
}

# Route table
resource "aws_route_table" "tenant_TransitRt" {
	vpc_id = "${aws_vpc.tenant.id}"
	route {
		cidr_block = "0.0.0.0/0"
		transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
	}
	tags = {
		Name = "${var.tenant_name}-TransitRt"
	}
}

resource "aws_route_table" "tenant_MgmtRt" {
	vpc_id = "${aws_vpc.tenant.id}"
	route {
		cidr_block = "0.0.0.0/0"
		transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
	}
	tags = {
		Name = "${var.tenant_name}-MgmtRt"
	}
}

resource "aws_route_table" "tenant_intRt" {
	vpc_id = "${aws_vpc.tenant.id}"
	route {
		cidr_block = "0.0.0.0/0"
		transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
	}
	tags = {
		Name = "${var.tenant_name}-intRt"
	}
}

# Assign route table to internal subnet
resource "aws_route_table_association" "tenant_int1" {
	subnet_id = "${aws_subnet.tenant_int1.id}"
	route_table_id = "${aws_route_table.tenant_intRt.id}"
}

# Assign route table to internal subnet
resource "aws_route_table_association" "tenant_int2" {
	subnet_id = "${aws_subnet.tenant_int2.id}"
	route_table_id = "${aws_route_table.tenant_intRt.id}"
}

output "Hub_Transit_Gateway_ID" { value = "${aws_ec2_transit_gateway.hubtgw.id}" }