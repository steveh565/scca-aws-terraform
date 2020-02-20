# Security VPC Networks
# VPC
resource "aws_vpc" "main" {
	cidr_block = var.security_vpc_cidr
	assign_generated_ipv6_cidr_block = true
	enable_dns_support = true
	enable_dns_hostnames = true
	tags = {
		Name = "vpc${var.tag_name}"
	}
}

# Create S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  tags = {
	Name = "vpcEpS3${var.tag_name}"
    Environment = var.prefix
  }
}

# Create EC2 VPC Endpoint
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.sg_internal.id,
  ]

  private_dns_enabled = true

  
  tags = {
	Name = "vpcEpEc2${var.tag_name}"
    Environment = var.prefix
  }
}

# Create Cloudwatch VPC Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.sg_internal.id,
  ]

  private_dns_enabled = true

  
  tags = {
	Name = "vpcEpLogs${var.tag_name}"
    Environment = var.prefix
  }
}

# Management subnet in AZ1
resource "aws_subnet" "az1_mgmt" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}a"
	cidr_block = var.az1_security_subnets.mgmt
	tags = {
		Name = "snetAz1Mgmt"
	}
}

# Management subnet in AZ2
resource "aws_subnet" "az2_mgmt" {
	vpc_id = aws_vpc.main.id
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
	vpc_id = aws_vpc.main.id
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


### TODO 
# Add 2x VPC Endpoints to each "tenant_external, dmzint, dmzext, pazext subnets
# S3 service & EC2 service - F5 cloud failover dependencies

### TODO
# Add S3 Storage Bucks for each pair of clustered F5 devices (using tags to map to F5 ha pair)

# Internet gateway
resource "aws_internet_gateway" "gw" {
	vpc_id = aws_vpc.main.id
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
		Name = var.vpc_tgw_name
	}
}

# Transit Gateway Attach
resource "aws_ec2_transit_gateway_vpc_attachment" "hubTgwAttach" {
    depends_on         = [aws_ec2_transit_gateway.hubtgw]
  	subnet_ids         = [aws_subnet.az1_transit.id, aws_subnet.az2_transit.id]
  	transit_gateway_id = aws_ec2_transit_gateway.hubtgw.id
  	vpc_id             = aws_vpc.main.id

  	tags = {
		Name = "${var.tag_name}-hubTgwAttach"
  	}
}

# TGW Route Table
resource "aws_ec2_transit_gateway_route_table" "hubtgwRt" {
  depends_on         = [aws_ec2_transit_gateway.hubtgw]
  transit_gateway_id = aws_ec2_transit_gateway.hubtgw.id
	tags = {
		Name = "${var.vpc_tgw_name}-RouteTable"
	}
}

# Route tables
resource "aws_route_table" "PazRt" {
	vpc_id = aws_vpc.main.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.gw.id
	}
	tags = {
		Name = "PazRT"
		f5_cloud_failover_label = var.gccap_cf_label
	}
}

resource "aws_route_table" "DmzExtRt" {
	vpc_id = aws_vpc.main.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.gw.id
	}
	tags = {
		Name = "DmzExtRT"
		f5_cloud_failover_label = var.gccap_cf_label
	}
}

resource "aws_route_table" "DmzIntRt" {
	vpc_id = aws_vpc.main.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.gw.id
	}
	tags = {
		Name = "DmzIntRT"
		f5_cloud_failover_label = var.gccap_cf_label
	}
}

resource "aws_route_table" "TransitRt" {
	depends_on = [aws_ec2_transit_gateway.hubtgw, aws_internet_gateway.gw]
	vpc_id = aws_vpc.main.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.gw.id
	}
	route {
		cidr_block = var.tenant_vpc_cidr
		transit_gateway_id = aws_ec2_transit_gateway.hubtgw.id
	}
	route {
		cidr_block = var.maz_vpc_cidr
		transit_gateway_id = aws_ec2_transit_gateway.hubtgw.id
	}
	tags = {
		Name = "TransitRT"
		f5_cloud_failover_label = var.gccap_cf_label
	}
}

resource "aws_route_table" "MgmtRt" {
	vpc_id = aws_vpc.main.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.gw.id
	}
	tags = {
		Name = "MgmtRT"
	}
}

# Assign route table to management subnet in AZ1
resource "aws_route_table_association" "az1_mgmt" {
	subnet_id = aws_subnet.az1_mgmt.id
	route_table_id = aws_route_table.MgmtRt.id
}

# Assign route table to management subnet in AZ2
resource "aws_route_table_association" "az2_mgmt" {
	subnet_id = aws_subnet.az2_mgmt.id
	route_table_id = aws_route_table.MgmtRt.id
}

# Assign route table to PAZ external subnet in AZ1
resource "aws_route_table_association" "az1_ext" {
	subnet_id = aws_subnet.az1_ext.id
	route_table_id = aws_route_table.PazRt.id
}

# Assign route table to PAZ external subnet in AZ2
resource "aws_route_table_association" "az2_ext" {
	subnet_id = aws_subnet.az2_ext.id
	route_table_id = aws_route_table.PazRt.id
}

# Assign route table to DMZ external subnet in AZ1
resource "aws_route_table_association" "az1_dmzExt" {
	subnet_id = aws_subnet.az1_dmzExt.id
	route_table_id = aws_route_table.DmzExtRt.id
}

# Assign route table to DMZ external subnet in AZ2
resource "aws_route_table_association" "az2_dmzExt" {
	subnet_id = aws_subnet.az2_dmzExt.id
	route_table_id = aws_route_table.DmzExtRt.id
}

# Assign route table to DMZ Internal subnet in AZ1
resource "aws_route_table_association" "az1_dmzInt" {
	subnet_id = aws_subnet.az1_dmzInt.id
	route_table_id = aws_route_table.DmzIntRt.id
}

# Assign route table to DMZ Internal subnet in AZ2
resource "aws_route_table_association" "az2_dmzInt" {
	subnet_id = aws_subnet.az2_dmzInt.id
	route_table_id = aws_route_table.DmzIntRt.id
}

# Assign route table to Transit subnet in AZ1
resource "aws_route_table_association" "az1_transit" {
	subnet_id = aws_subnet.az1_transit.id
	route_table_id = aws_route_table.TransitRt.id
}

# Assign route table to Transit subnet in AZ2
resource "aws_route_table_association" "az2_transit" {
	subnet_id = aws_subnet.az2_transit.id
	route_table_id = aws_route_table.TransitRt.id
}
