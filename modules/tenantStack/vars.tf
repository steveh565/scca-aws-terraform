# AWS Creds
variable "SP" {
  type = "map"
  default = {
    access_key = "NULL_KEY"
    secret_key = "NULL_SECRET"
  }
}

# Input Variables
variable aws_region { default = "ca-central-1" }

# Prefixes
variable prefix { default = "SHSCA" }
variable tenant_name { default = "Tenant" }

#SSH public key path
variable key_path { default = "~/.ssh/id_rsa.pub" }

#Source IPv4 CIDR block(s) allowed to access management
variable mgmt_asrc { default = ["0.0.0.0/0"] }

# Platform settings variables
variable az1_f5Hostname      { default = "edgeF5vm01" }
variable az2_f5Hostname      { default = "edgeF5vm02" }
variable f5Domainname        { default = "f5labs.gc.ca" }

variable uname      { default = "awsops" }
variable upassword  { default = "Canada12345" }
variable ntp_server { default = "0.us.pool.ntp.org" }
variable timezone   { default = "UTC" }

# Local Security groups
variable sgExternal { default = "sgExternal" }
variable sgExtMgmt { default = "sgExtMgmt" }
variable sgInternal { default = "sgInternal" }

# Security VPC information
variable security_vpc_cidr { default = "10.1.0.0/16" }
variable security_vpc_transit_aip_cidr { default = "100.65.5.0/29" }

# Cloudwatch information
variable cwLogGroup { default = "f5telemetry" }

# Tenant VPC Network
variable tenant_vpc_cidr { default = "10.21.0.0/16" }
variable tenant_aip_cidr { default = "100.66.71.240/29" }
variable tenant_gre_cidr { default = "172.16.240/30"}
variable tenant_cf_label { default = "tenant_az_failover" }
variable tgwId { default = "tgw-unknown" }

#derived values
locals {
    #subnets
    vpc_dns           = "${cidrhost(var.tenant_vpc_cidr, 2)}"
    az1MgmtSnet       = "${cidrsubnet(var.tenant_vpc_cidr, 8, 0)}"
    az2MgmtSnet       = "${cidrsubnet(var.tenant_vpc_cidr, 8, 10)}"
    az1ExtSnet        = "${cidrsubnet(var.tenant_vpc_cidr, 8, 1)}"
    az2ExtSnet        = "${cidrsubnet(var.tenant_vpc_cidr, 8, 11)}"
    az1IntSnet        = "${cidrsubnet(var.tenant_vpc_cidr, 8, 2)}"
    az2IntSnet        = "${cidrsubnet(var.tenant_vpc_cidr, 8, 12)}"

    #bigip addresses
    az1MgmtIp         = "${cidrhost(local.az1MgmtSnet, 11)}"
    az2MgmtIp         = "${cidrhost(local.az2MgmtSnet, 11)}"
    az1ExtSelfIp      = "${cidrhost(local.az1ExtSnet, 11)}"
    az2ExtSelfIp      = "${cidrhost(local.az2ExtSnet, 11)}"
    az1IntSelfIp      = "${cidrhost(local.az1IntSnet, 11)}"
    az2IntSelfIp      = "${cidrhost(local.az2IntSnet, 11)}"

    aip_az1ExtSelfIp  = "${cidrhost(var.tenant_aip_cidr, 1)}"
    aip_az1ExtFloatIp = "${cidrhost(var.tenant_aip_cidr, 3)}"
    aip_az2ExtSelfIp  = "${cidrhost(var.tenant_aip_cidr, 2)}"

    greTunLocAddr     = "${cidrhost(var.tenant_aip_cidr, 3)}"
    greTunRemAddr     = "${cidrhost(var.security_vpc_transit_aip_cidr, 3)}"
    greSelfIp         = "${cidrhost(var.tenant_gre_cidr, 2)}"
    greNextHop        = "${cidrhost(var.tenant_gre_cidr, 1)}"

    #workload addresses
    az1BastionHostIp  = "${cidrhost(local.az1IntSnet, 21)}"
    az2BastionHostIp  = "${cidrhost(local.az2IntSnet, 21)}"

    #cloudwatch vars
    cwLogGroupName    = "${var.tenant_name}-${var.cwLogGroup}"
    az1_cwLogStream   = "${var.tenant_name}-${var.az1_f5Hostname}"
    az2_cwLogStream   = "${var.tenant_name}-${var.az2_f5Hostname}"
}
