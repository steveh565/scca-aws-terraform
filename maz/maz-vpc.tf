# VPC
resource "aws_vpc" "maz" {
	cidr_block = "${var.maz_vpc_cidr}"
	assign_generated_ipv6_cidr_block = true
	enable_dns_support = true
	enable_dns_hostnames = true
	tags = {
		Name = "vpc${var.tag_name}-${var.maz_name}"
		Tenant = "${var.maz_name}"
	}
}

# Create S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.maz.id}"
  service_name = "com.amazonaws.${var.aws_region}.s3"

  tags = {
	Name = "vpcEpS3${var.tag_name}"
    Environment = "${var.prefix}"
  }
}

# Create EC2 VPC Endpoint
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "${aws_vpc.maz.id}"
  service_name      = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.maz_sg_internal.id}",
  ]

  private_dns_enabled = true

  
  tags = {
	Name = "vpcEpEc2${var.tag_name}"
    Environment = "${var.prefix}"
  }
}

# Create Cloudwatch VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id            = "${aws_vpc.maz.id}"
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.maz_sg_internal.id}",
  ]

  private_dns_enabled = true

  
  tags = {
	Name = "vpcEpLogs${var.tag_name}"
    Environment = "${var.prefix}"
  }
}

# Management subnet in AZ1
resource "aws_subnet" "az1_maz_mgmt" {
	vpc_id = "${aws_vpc.maz.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_maz_subnets.mgmt
	tags = {
		Name = "${var.maz_name}-snetMgmt1"
		Tenant = "${var.maz_name}"
	}
}

# Management subnet in AZ2
resource "aws_subnet" "az2_maz_mgmt" {
	vpc_id = "${aws_vpc.maz.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_maz_subnets.mgmt
	tags = {
		Name = "${var.maz_name}-snetMgmt2"
		Tenant = "${var.maz_name}"
	}
}

# External subnet in AZ1
resource "aws_subnet" "az1_maz_ext" {
	vpc_id = "${aws_vpc.maz.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_maz_subnets.transit
	tags = {
		Name = "${var.maz_name}-snetExternal1"
		Tenant = "${var.maz_name}"
	}
}

# External subnet in AZ2
resource "aws_subnet" "az2_maz_ext" {
	vpc_id = "${aws_vpc.maz.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_maz_subnets.transit
	tags = {
		Name = "${var.maz_name}-snetExternal2"
		Tenant = "${var.maz_name}"
	}
}

# Internal subnet in AZ1
resource "aws_subnet" "az1_maz_int" {
	vpc_id = "${aws_vpc.maz.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_maz_subnets.internal
	tags = {
		Name = "${var.maz_name}-snetInternal1"
		Tenant = "${var.maz_name}"
	}
}

# Internal subnet in AZ2
resource "aws_subnet" "az2_maz_int" {
	vpc_id = "${aws_vpc.maz.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_maz_subnets.internal
	tags = {
		Name = "${var.maz_name}-snetInternal2"
		Tenant = "${var.maz_name}"
	}
}

/**/
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
resource "aws_ec2_transit_gateway_vpc_attachment" "mazTgwAttach" {
  	subnet_ids         = ["${aws_subnet.az1_maz_ext.id}", "${aws_subnet.az2_maz_ext.id}"]
  	transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
  	vpc_id             = "${aws_vpc.maz.id}"

  	tags = {
		Name = "${var.maz_name}-TgwAttach"
		Tenant = "${var.maz_name}"
  	}
}


# Internet gateway
resource "aws_internet_gateway" "mazGw" {
	vpc_id = "${aws_vpc.maz.id}"
	tags = {
		Name = "igw${var.maz_name}"
	}
}

# Route table
resource "aws_route_table" "maz_TransitRt" {
	vpc_id = "${aws_vpc.maz.id}"
/*
	route {
		cidr_block = "10.1.0.0/0"
		transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
		#gateway_id = "${aws_internet_gateway.mazGw.id}"
	}
*/
	route {
		cidr_block = "0.0.0.0/0"
		#transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
		gateway_id = "${aws_internet_gateway.mazGw.id}"
	}
	tags = {
		Name = "${var.maz_name}-TransitRt"
	}
}

# Assign route table to internal subnet
resource "aws_route_table_association" "az1_maz_ext" {
	subnet_id = "${aws_subnet.az1_maz_ext.id}"
	route_table_id = "${aws_route_table.maz_TransitRt.id}"
}

# Assign route table to internal subnet
resource "aws_route_table_association" "az2_maz_ext" {
	subnet_id = "${aws_subnet.az2_maz_ext.id}"
	route_table_id = "${aws_route_table.maz_TransitRt.id}"
}


resource "aws_route_table" "maz_MgmtRt" {
	vpc_id = "${aws_vpc.maz.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.mazGw.id}"
	}
	tags = {
		Name = "${var.maz_name}-MgmtRt"
	}
}


# Assign route table to internal subnet
resource "aws_route_table_association" "az1_maz_mgmt" {
	subnet_id = "${aws_subnet.az1_maz_mgmt.id}"
	route_table_id = "${aws_route_table.maz_MgmtRt.id}"
}

# Assign route table to internal subnet
resource "aws_route_table_association" "az2_maz_mgmt" {
	subnet_id = "${aws_subnet.az2_maz_mgmt.id}"
	route_table_id = "${aws_route_table.maz_MgmtRt.id}"
}

resource "aws_route_table" "maz_intRt" {
	vpc_id = "${aws_vpc.maz.id}"
	route {
		cidr_block = "10.1.0.0/16"
		transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
		#gateway_id = "${aws_internet_gateway.mazGw.id}"
	}
	route {
		cidr_block = "0.0.0.0/0"
		#transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
		gateway_id = "${aws_internet_gateway.mazGw.id}"
	}
	tags = {
		Name = "${var.maz_name}-intRt"
	}
}


# Assign route table to internal subnet
resource "aws_route_table_association" "az1_maz_int" {
	subnet_id = "${aws_subnet.az1_maz_int.id}"
	route_table_id = "${aws_route_table.maz_intRt.id}"
}

# Assign route table to internal subnet
resource "aws_route_table_association" "az2_maz_int" {
	subnet_id = "${aws_subnet.az2_maz_int.id}"
	route_table_id = "${aws_route_table.maz_intRt.id}"
}
