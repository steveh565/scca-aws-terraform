# GC-vCAP VPC Networks

resource "aws_vpc" "main" {
	cidr_block = var.security_vpc_cidr
	assign_generated_ipv6_cidr_block = false
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
    Environment = "${var.prefix}"
  }
}

# Create EC2 VPC Endpoint
resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.sg_internal.id]

  private_dns_enabled = true
  subnet_ids = [aws_subnet.az1_mgmt.id, aws_subnet.az2_mgmt.id]

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

  security_group_ids = [aws_security_group.sg_internal.id]

  private_dns_enabled = true
  subnet_ids = [aws_subnet.az1_mgmt.id, aws_subnet.az2_mgmt.id]
  
  tags = {
	Name = "vpcEpLogs${var.tag_name}"
    Environment = "${var.prefix}"
  }
}

# Management subnet in AZ1
resource "aws_subnet" "az1_mgmt" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}a"
	cidr_block = local.az1MgmtSnet
	tags = {
		Name = "snetAz1Mgmt"
	}
}

# Management subnet in AZ2
resource "aws_subnet" "az2_mgmt" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}b"
	cidr_block = local.az2MgmtSnet
	tags = {
		Name = "snetAz2Mgmt"
	}
}

# External subnet in AZ1
resource "aws_subnet" "az1_ext" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}a"
	cidr_block = local.az1PazExtSnet
	tags = {
		Name = "snetAz1External"
	}
}

# External subnet in AZ2
resource "aws_subnet" "az2_ext" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}b"
	cidr_block = local.az2PazExtSnet
	tags = {
		Name = "snetAz2External"
	}
}

# DMZ External subnet in AZ1
resource "aws_subnet" "az1_dmzExt" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}a"
	cidr_block = local.az1DmzExtSnet
	tags = {
		Name = "snetAz1DmzExt"
	}
}

# DMZ External subnet in AZ2
resource "aws_subnet" "az2_dmzExt" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}b"
	cidr_block = local.az2DmzExtSnet
	tags = {
		Name = "snetAz2DmzExt"
	}
}

# DMZ Internal subnet in AZ1
resource "aws_subnet" "az1_dmzInt" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}a"
	cidr_block = local.az1DmzIntSnet
	tags = {
		Name = "snetAz2DmzInt"
	}
}

# DMZ Internal subnet in AZ2
resource "aws_subnet" "az2_dmzInt" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}b"
	cidr_block = local.az2DmzIntSnet
	tags = {
		Name = "snetAz2DmzInt"
	}
}

# DMZ External subnet in AZ1
resource "aws_subnet" "az1_transit" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}a"
	cidr_block = local.az1TransitIntSnet
	tags = {
		Name = "snetAz1Transit"
	}
}

# DMZ External subnet in AZ2
resource "aws_subnet" "az2_transit" {
	vpc_id = aws_vpc.main.id
	availability_zone = "${var.aws_region}b"
	cidr_block = local.az2TransitIntSnet
	tags = {
		Name = "snetAz2Transit"
	}
}

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
		Name = "${var.vpc_tgw_name}"
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

/*
resource "aws_ec2_transit_gateway_route" "TgwRt_defaultRoute" {
  depends_on                     = [aws_ec2_transit_gateway_vpc_attachment.hubTgwAttach]
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hubtgwRt
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hubTgwAttach
}
*/

resource "aws_ec2_transit_gateway_route" "TgwRt_toSecurityStack" {
  depends_on                     = [aws_ec2_transit_gateway_vpc_attachment.hubTgwAttach]
  destination_cidr_block         = var.aip_Transit_int_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway.hubtgw.association_default_route_table_id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hubTgwAttach.id
}


# Mgmt Route table
resource "aws_route_table" "MgmtRt" {
	vpc_id = aws_vpc.main.id
	tags = {
		Name = "${var.prefix}-MgmtRT"
	}
}

resource "aws_route" "MgmtRt_defaultRoute" {
	depends_on = [aws_route_table.MgmtRt, aws_internet_gateway.gw]
	route_table_id = aws_route_table.MgmtRt.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.gw.id
}

# Paz Route table
resource "aws_route_table" "PazRt" {
	vpc_id = aws_vpc.main.id
	tags = {
		Name = "${var.prefix}-PazRT"
		f5_cloud_failover_label = "${var.gccap_cf_label}"
	}
	lifecycle {    
		ignore_changes = all
  	} 
}

resource "aws_route" "PazRt_defaultRoute" {
	depends_on = [aws_route_table.PazRt, aws_internet_gateway.gw]
	route_table_id = aws_route_table.PazRt.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.gw.id
}


# DmzExt Route table
resource "aws_route_table" "DmzExtRt" {
	vpc_id = aws_vpc.main.id
	tags = {
		Name = "${var.prefix}-DmzExtRT"
		f5_cloud_failover_label = "${var.gccap_cf_label}"
	}
	lifecycle {    
		ignore_changes = all
  	} 
}

resource "aws_route" "DmzExtRt_defaultRoute" {
	depends_on = [aws_route_table.DmzExtRt, aws_network_interface.az1_internal, aws_internet_gateway.gw]
	route_table_id = aws_route_table.DmzExtRt.id
	destination_cidr_block = "0.0.0.0/0"
	#network_interface_id = aws_network_interface.az1_internal.id
	gateway_id = aws_internet_gateway.gw.id
	lifecycle {    
		#ignore_changes = [network_interface_id]
		ignore_changes = [gateway_id]
  	} 
}

resource "aws_route" "DmzExtRt_aipPazRoute" {
	depends_on = [aws_route_table.DmzExtRt, aws_network_interface.az1_internal]
	route_table_id = aws_route_table.DmzExtRt.id
	destination_cidr_block = var.aip_paz_dmz_ext_cidr  #"100.65.1.0/29"
	network_interface_id = aws_network_interface.az1_internal.id
	lifecycle {    
		ignore_changes = [network_interface_id]
  	}
}

resource "aws_route" "DmzExtRt_aipDmzRoute" {
	depends_on = [aws_route_table.DmzExtRt, aws_network_interface.az1_dmz_external]
	route_table_id = aws_route_table.DmzExtRt.id
	destination_cidr_block = var.aip_dmz_ext_cidr  #"100.65.2.0/29"
	network_interface_id = aws_network_interface.az1_dmz_external.id
	lifecycle {    
		ignore_changes = [network_interface_id]
  	}
}

resource "aws_route" "DmzExtRt_aipTenantVipRoute" {
	depends_on = [aws_route_table.DmzExtRt, aws_network_interface.az1_dmz_external]
	route_table_id = aws_route_table.DmzExtRt.id
	destination_cidr_block = var.aip_tenants_vip_cidr  #"100.100.0.0/16"
	network_interface_id = aws_network_interface.az1_dmz_external.id
	lifecycle {    
		ignore_changes = [network_interface_id]
  	}
}

#DmzInt Route table
resource "aws_route_table" "DmzIntRt" {
	vpc_id = aws_vpc.main.id
	tags = {
		Name = "${var.prefix}-DmzIntRT"
		f5_cloud_failover_label = "${var.gccap_cf_label}"
	}
	lifecycle {    
		ignore_changes = all
  	} 
}

resource "aws_route" "DmzIntRt_defaultRoute" {
	depends_on = [aws_route_table.DmzIntRt, aws_network_interface.az1_dmz_internal, aws_internet_gateway.gw]
	route_table_id = aws_route_table.DmzIntRt.id
	destination_cidr_block = "0.0.0.0/0"
	#network_interface_id = aws_network_interface.az1_dmz_internal.id
	gateway_id = aws_internet_gateway.gw.id
	lifecycle {    
		#ignore_changes = [network_interface_id]
		ignore_changes = [gateway_id]
  	} 
}

resource "aws_route" "DmzIntRt_aipDmzExtRoute" {
	depends_on = [aws_route_table.DmzIntRt, aws_network_interface.az1_dmz_internal]
	route_table_id = aws_route_table.DmzIntRt.id
	destination_cidr_block = var.aip_dmz_int_cidr  #"100.65.3.0/29"
	network_interface_id = aws_network_interface.az1_dmz_internal.id
	lifecycle {    
		ignore_changes = [network_interface_id]
  	}
}

resource "aws_route" "DmzIntRt_aipDmzIntRoute" {
	depends_on = [aws_route_table.DmzIntRt, aws_network_interface.az1_transit_external]
	route_table_id = aws_route_table.DmzIntRt.id
	destination_cidr_block = var.aip_dmzTransit_ext_cidr  #"100.65.4.0/29"
	network_interface_id = aws_network_interface.az1_transit_external.id
	lifecycle {    
		ignore_changes = [network_interface_id]
  	}
}

resource "aws_route" "DmzIntRt_aipTenantVipRoute" {
	depends_on = [aws_route_table.DmzIntRt, aws_network_interface.az1_transit_external]
	route_table_id = aws_route_table.DmzIntRt.id
	destination_cidr_block = var.aip_tenants_vip_cidr  #"100.100.0.0/16"
	network_interface_id = aws_network_interface.az1_transit_external.id
	lifecycle {    
		ignore_changes = [network_interface_id]
  	}
}

# Transit Route table
resource "aws_route_table" "TransitRt" {
	depends_on = [aws_ec2_transit_gateway.hubtgw, aws_internet_gateway.gw]
	vpc_id = aws_vpc.main.id
	tags = {
		Name = "${var.prefix}-TransitRT"
		f5_cloud_failover_label = "${var.gccap_cf_label}"
	}
	lifecycle {    
		ignore_changes = all
  	} 
}

resource "aws_route" "TransitRt_defaultRoute" {
	depends_on = [aws_route_table.TransitRt, aws_network_interface.az1_transit_internal, aws_internet_gateway.gw]
	route_table_id = aws_route_table.TransitRt.id
	destination_cidr_block = "0.0.0.0/0"
	#network_interface_id = aws_network_interface.az1_transit_internal.id
	gateway_id = aws_internet_gateway.gw.id
	lifecycle {    
		#ignore_changes = [network_interface_id]
		ignore_changes = [gateway_id]
  	} 
}

resource "aws_route" "TransitRt_aipTransitRoute" {
	depends_on = [aws_route_table.TransitRt, aws_network_interface.az1_transit_internal]
	route_table_id = aws_route_table.TransitRt.id
	destination_cidr_block = var.aip_Transit_int_cidr  #"100.65.5.0/29"
	network_interface_id = aws_network_interface.az1_transit_internal.id
	lifecycle {    
		ignore_changes = [network_interface_id]
  	}
}

resource "aws_route" "TransitRt_aipTenantsRoute" {
	depends_on = [aws_route_table.TransitRt, aws_ec2_transit_gateway.hubtgw]
	route_table_id = aws_route_table.TransitRt.id
	destination_cidr_block = var.aip_tenants_cidr  #"100.66.64.0/21"
	transit_gateway_id = aws_ec2_transit_gateway.hubtgw.id
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
