# VPC
resource "aws_vpc" "tenant" {
	cidr_block = var.tenant_vpc_cidr
	assign_generated_ipv6_cidr_block = false
	enable_dns_support = true
	enable_dns_hostnames = true
	tags = {
		Name = "${var.prefix}-${var.tenant_name}-vpc"
		Tenant = var.tenant_name
        ResourceGroup = var.prefix
	}
}

# Create S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
    vpc_id       = aws_vpc.tenant.id
    service_name = "com.amazonaws.${var.aws_region}.s3"

    tags = {
        name = "${var.prefix}-${var.tenant_name}-s3ep"
        ResourceGroup = var.prefix
    }
}

resource "aws_vpc_endpoint_route_table_association" "s3_rta" {
  route_table_id  = aws_route_table.tenant_TransitRt.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# Create EC2 VPC Endpoint
resource "aws_vpc_endpoint" "ec2" {
    
    vpc_id            = aws_vpc.tenant.id
    service_name      = "com.amazonaws.${var.aws_region}.ec2"
    vpc_endpoint_type = "Interface"
    security_group_ids = [aws_security_group.sg_internal.id]
    private_dns_enabled = true
    subnet_ids = [aws_subnet.az1_tenant_mgmt.id, aws_subnet.az2_tenant_mgmt.id]
    tags = {
        name = "${var.prefix}-${var.tenant_name}-ec2ep"
        ResourceGroup = var.prefix
    }
}

# Create Cloudwatch VPC Endpoint
# ToDo: make logs endpoint unique to the tenant VPC??
resource "aws_vpc_endpoint" "logs" {
    
    vpc_id            = aws_vpc.tenant.id
    service_name      = "com.amazonaws.${var.aws_region}.logs"
    vpc_endpoint_type = "Interface"
    security_group_ids = [aws_security_group.sg_internal.id]
    private_dns_enabled = true
    subnet_ids = [aws_subnet.az1_tenant_mgmt.id, aws_subnet.az2_tenant_mgmt.id]
    tags = {
        name = "${var.prefix}-${var.tenant_name}-LogsEp"
        Environment = var.prefix
        ResourceGroup = var.prefix
    }
}


# Management subnet in AZ1
resource "aws_subnet" "az1_tenant_mgmt" {
    
	vpc_id = aws_vpc.tenant.id
	availability_zone = "${var.aws_region}a"
	cidr_block = local.az1MgmtSnet
	tags = {
		name = "${var.prefix}-${var.tenant_name}-az1_mgmtSnet"
		Tenant = var.tenant_name
        ResourceGroup = var.prefix
	}
}

# Management subnet in AZ2
resource "aws_subnet" "az2_tenant_mgmt" {
    
	vpc_id = aws_vpc.tenant.id
	availability_zone = "${var.aws_region}b"
	cidr_block = local.az2MgmtSnet
	tags = {
		name = "${var.prefix}-${var.tenant_name}-az2_mgmtSnet"
		Tenant = var.tenant_name
        ResourceGroup = var.prefix
	}
}

# External subnet in AZ1
resource "aws_subnet" "az1_tenant_ext" {
    
	vpc_id = aws_vpc.tenant.id
	availability_zone = "${var.aws_region}a"
	cidr_block = local.az1ExtSnet
	tags = {
		name = "${var.prefix}-${var.tenant_name}-az1_extSnet"
		Tenant = var.tenant_name
        ResourceGroup = var.prefix
	}
}

# External subnet in AZ2
resource "aws_subnet" "az2_tenant_ext" {
    
	vpc_id = aws_vpc.tenant.id
	availability_zone = "${var.aws_region}b"
	cidr_block = local.az2ExtSnet
	tags = {
		name = "${var.prefix}-${var.tenant_name}-az2_extSnet"
		Tenant = var.tenant_name
        ResourceGroup = var.prefix
	}
}

# Internal subnet in AZ1
resource "aws_subnet" "az1_tenant_int" {
    
	vpc_id = aws_vpc.tenant.id
	availability_zone = "${var.aws_region}a"
	cidr_block = local.az1IntSnet
	tags = {
		name = "${var.prefix}-${var.tenant_name}-az1_intSnet"
		Tenant = var.tenant_name
        ResourceGroup = var.prefix
	}
}

# Internal subnet in AZ2
resource "aws_subnet" "az2_tenant_int" {
    
	vpc_id = aws_vpc.tenant.id
	availability_zone = "${var.aws_region}b"
	cidr_block = local.az2IntSnet
	tags = {
		name = "${var.prefix}-${var.tenant_name}-az2_intSnet"
		Tenant = var.tenant_name
        ResourceGroup = var.prefix
	}
}

# Transit Gateway Attach
resource "aws_ec2_transit_gateway_vpc_attachment" "tenantTgwAttach" {
    
  	subnet_ids         = [aws_subnet.az1_tenant_ext.id, aws_subnet.az2_tenant_ext.id]
  	transit_gateway_id = var.tgwId
  	vpc_id             = aws_vpc.tenant.id

  	tags = {
		name = "${var.prefix}-${var.tenant_name}-gcCap-tgwAttach"
		Tenant = var.tenant_name
        ResourceGroup = var.prefix
  	}
}


# Internet gateway
resource "aws_internet_gateway" "tenantGw" {
	vpc_id = aws_vpc.tenant.id
	tags = {
		Name = "${var.prefix}-${var.tenant_name}-igw"
        ResourceGroup = var.prefix
	}
}

# Route table
resource "aws_route_table" "tenant_TransitRt" {
	vpc_id = aws_vpc.tenant.id
	route {
		cidr_block = var.tenant_aip_cidr
		network_interface_id = aws_network_interface.az1_tenant_external.id
	}
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.tenantGw.id
		#This route is for VM onboarding and can be safely removed after Onboarding is complete
	}
	route {
		cidr_block = var.security_vpc_cidr
		transit_gateway_id = var.tgwId
	}
	route {
		cidr_block = var.security_vpc_transit_aip_cidr
		transit_gateway_id = var.tgwId
	}
	tags = {
		Name = "${var.prefix}-${var.tenant_name}-TransitRt"
    	f5_cloud_failover_label = var.tenant_cf_label
        ResourceGroup = var.prefix
	}
	lifecycle {    
		ignore_changes = all
  	}
}

# Assign route table to internal subnet
resource "aws_route_table_association" "az1_tenant_ext" {
	subnet_id = aws_subnet.az1_tenant_ext.id
	route_table_id = aws_route_table.tenant_TransitRt.id

}

# Assign route table to internal subnet
resource "aws_route_table_association" "az2_tenant_ext" {
	subnet_id = aws_subnet.az2_tenant_ext.id
	route_table_id = aws_route_table.tenant_TransitRt.id

}

# Mgmt Route Table
resource "aws_route_table" "tenant_MgmtRt" {
	vpc_id = aws_vpc.tenant.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.tenantGw.id
	}
	tags = {
		Name = "${var.prefix}-${var.tenant_name}-MgmtRt"
        ResourceGroup = var.prefix
	}
}


# Assign route table to internal subnet
resource "aws_route_table_association" "az1_tenant_mgmt" {
	subnet_id = aws_subnet.az1_tenant_mgmt.id
	route_table_id = aws_route_table.tenant_MgmtRt.id

}

# Assign route table to internal subnet
resource "aws_route_table_association" "az2_tenant_mgmt" {
	subnet_id = aws_subnet.az2_tenant_mgmt.id
	route_table_id = aws_route_table.tenant_MgmtRt.id

}

resource "aws_route_table" "tenant_intRt" {
	vpc_id = aws_vpc.tenant.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.tenantGw.id
        #This route is for VM onboarding and should be updated to point to the ENI of the active F5 unit in the cluster once VM onboarding is complete
	}
	tags = {
		Name = "${var.prefix}-${var.tenant_name}--intRt"
        ResourceGroup = var.prefix
        f5_cloud_failover_label = var.tenant_cf_label
	}
	lifecycle {    
		ignore_changes = all
  	}
}


# Assign route table to internal subnet
resource "aws_route_table_association" "az1_tenant_int" {
	subnet_id = aws_subnet.az1_tenant_int.id
	route_table_id = aws_route_table.tenant_intRt.id

}

# Assign route table to internal subnet
resource "aws_route_table_association" "az2_tenant_int" {
	subnet_id = aws_subnet.az2_tenant_int.id
	route_table_id = aws_route_table.tenant_intRt.id

}
