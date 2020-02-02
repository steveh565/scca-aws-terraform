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

# Create S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.tenant.id}"
  service_name = "com.amazonaws.${var.aws_region}.s3"

  tags = {
	Name = "vpcEpS3${var.tag_name}"
    Environment = "${var.prefix_name}"
  }
}

# Create EC2 VPC Endpoint
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = "${aws_vpc.tenant.id}"
  service_name      = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.tenant_sg_internal.id}",
  ]

  private_dns_enabled = true

  
  tags = {
	Name = "vpcEpEc2${var.tag_name}"
    Environment = "${var.prefix_name}"
  }
}

# Create Cloudwatch VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id            = "${aws_vpc.tenant.id}"
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.tenant_sg_internal.id}",
  ]

  private_dns_enabled = true

  
  tags = {
	Name = "vpcEpLogs${var.tag_name}"
    Environment = "${var.prefix_name}"
  }
}

# Management subnet in AZ1
resource "aws_subnet" "az1_tenant_mgmt" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_tenant_subnets.mgmt
	tags = {
		Name = "${var.tenant_name}-snetMgmt1"
		Tenant = "${var.tenant_name}"
	}
}

# Management subnet in AZ2
resource "aws_subnet" "az2_tenant_mgmt" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_tenant_subnets.mgmt
	tags = {
		Name = "${var.tenant_name}-snetMgmt2"
		Tenant = "${var.tenant_name}"
	}
}

# External subnet in AZ1
resource "aws_subnet" "az1_tenant_ext" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_tenant_subnets.transit
	tags = {
		Name = "${var.tenant_name}-snetExternal1"
		Tenant = "${var.tenant_name}"
	}
}

# External subnet in AZ2
resource "aws_subnet" "az2_tenant_ext" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_tenant_subnets.transit
	tags = {
		Name = "${var.tenant_name}-snetExternal2"
		Tenant = "${var.tenant_name}"
	}
}

# Internal subnet in AZ1
resource "aws_subnet" "az1_tenant_int" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_tenant_subnets.internal
	tags = {
		Name = "${var.tenant_name}-snetInternal1"
		Tenant = "${var.tenant_name}"
	}
}

# Internal subnet in AZ2
resource "aws_subnet" "az2_tenant_int" {
	vpc_id = "${aws_vpc.tenant.id}"
	availability_zone = "${var.aws_region}b"
	cidr_block = var.az2_tenant_subnets.internal
	tags = {
		Name = "${var.tenant_name}-snetInternal2"
		Tenant = "${var.tenant_name}"
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
resource "aws_ec2_transit_gateway_vpc_attachment" "tenantTgwAttach" {
  	subnet_ids         = ["${aws_subnet.az1_tenant_ext.id}", "${aws_subnet.az2_tenant_ext.id}"]
  	transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
  	vpc_id             = "${aws_vpc.tenant.id}"

  	tags = {
		Name = "${var.tenant_name}-TgwAttach"
		Tenant = "${var.tenant_name}"
  	}
}


# Internet gateway
resource "aws_internet_gateway" "tenantGw" {
	vpc_id = "${aws_vpc.tenant.id}"
	tags = {
		Name = "igw${var.tenant_name}"
	}
}

# Route table
resource "aws_route_table" "tenant_TransitRt" {
	vpc_id = "${aws_vpc.tenant.id}"
	route {
		cidr_block = "10.1.0.0/16"
		transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
		#gateway_id = "${aws_internet_gateway.tenantGw.id}"
	}
	route {
		cidr_block = "0.0.0.0/0"
		#transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
		gateway_id = "${aws_internet_gateway.tenantGw.id}"
	}	
	tags = {
		Name = "${var.tenant_name}-TransitRt"
	}
}

# Assign route table to internal subnet
resource "aws_route_table_association" "az1_tenant_ext" {
	subnet_id = "${aws_subnet.az1_tenant_ext.id}"
	route_table_id = "${aws_route_table.tenant_TransitRt.id}"
}

# Assign route table to internal subnet
resource "aws_route_table_association" "az2_tenant_ext" {
	subnet_id = "${aws_subnet.az2_tenant_ext.id}"
	route_table_id = "${aws_route_table.tenant_TransitRt.id}"
}


resource "aws_route_table" "tenant_MgmtRt" {
	vpc_id = "${aws_vpc.tenant.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.tenantGw.id}"
	}
	tags = {
		Name = "${var.tenant_name}-MgmtRt"
	}
}


# Assign route table to internal subnet
resource "aws_route_table_association" "az1_tenant_mgmt" {
	subnet_id = "${aws_subnet.az1_tenant_mgmt.id}"
	route_table_id = "${aws_route_table.tenant_MgmtRt.id}"
}

# Assign route table to internal subnet
resource "aws_route_table_association" "az2_tenant_mgmt" {
	subnet_id = "${aws_subnet.az2_tenant_mgmt.id}"
	route_table_id = "${aws_route_table.tenant_MgmtRt.id}"
}

resource "aws_route_table" "tenant_intRt" {
	vpc_id = "${aws_vpc.tenant.id}"
	route {
		cidr_block = "10.1.0.0/16"
		transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
		#gateway_id = "${aws_internet_gateway.tenantGw.id}"
	}
	route {
		cidr_block = "0.0.0.0/0"
		#transit_gateway_id = "${aws_ec2_transit_gateway.hubtgw.id}"
		gateway_id = "${aws_internet_gateway.tenantGw.id}"
	}
	tags = {
		Name = "${var.tenant_name}-intRt"
	}
}


# Assign route table to internal subnet
resource "aws_route_table_association" "az1_tenant_int" {
	subnet_id = "${aws_subnet.az1_tenant_int.id}"
	route_table_id = "${aws_route_table.tenant_intRt.id}"
}

# Assign route table to internal subnet
resource "aws_route_table_association" "az2_tenant_int" {
	subnet_id = "${aws_subnet.az2_tenant_int.id}"
	route_table_id = "${aws_route_table.tenant_intRt.id}"
}
