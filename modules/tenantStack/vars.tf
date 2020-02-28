# Input Variables
variable aws_region { default = "ca-central-1" }

# Prefixes
variable prefix { description = "String: Globally unique Prefix for the enviorment" }
variable tenant_prefix { description = "String: Globally unique Tenant Prefix for the Tenant environment" }
variable tenant_name { description = "String: Globally unique Tenant name" }

# DNS
variable f5Domainname        { description = "String: Fully Qualified Domain Name for the enviorment" }

#SSH public key path
variable key_path { description = "String: Path the Public SSH Key" }

#Source IPv4 CIDR block(s) allowed to access management
variable mgmt_asrc { description = "List: Source IP Access Control List" }

# Platform settings variables
variable uname { description = "Default Admin Username" }
variable upassword { description = "Password for Default Admin" }

variable dns_server { default = "169.254.169.253" }
variable ntp_server { default = "0.us.pool.ntp.org" }
variable timezone   { default = "UTC" }
variable libs_dir   { default = "/config/cloud/aws/node_modules" }

variable az1_tenantF5_onboard_script { default = "az1_tenantF5_onboard.sh" }
variable az2_tenantF5_onboard_script { default = "az2_tenantF5_onboard.sh" }
variable onboard_log	{ default = "/var/log/startup-script.log" }

variable ami_f5image_name { default = "ami-038e6394d715e5eac" }
variable ami_f5image_type { default = "AllTwoBootLocations" }
variable ami_image_version { default = "latest" }

# Local Security groups
variable sgExternal { default = "sgExternal" }
variable sgExtMgmt { default = "sgExtMgmt" }
variable sgInternal { default = "sgInternal" }

# Security VPC information
variable security_vpc_transit_aip_cidr { description = "String: SecurityStack VPC Transit::Internal Alien-IP CIDR" }

# Cloudwatch information
variable cwLogGroup { default = "f5telemetry" }

# Tenant VPC Network
variable tenant_vpc_cidr { description = "String: Tenant VPC CIDR" }
variable tenant_aip_cidr { description = "String: Tenant Alien-IP CIDR" }
variable tenant_gre_cidr { description = "String: Tenant GRE Tunnel to Security VPC CIDR" }

variable tenant_cf_label { description = "String: Globally unique F5 CloudFailover Extension tenant label" }
variable tgwId { description = "String: SecurityStack Transit Gateway ID" }

variable az1_tenantF5 {
  description = "Az1 tenantF5 baseConfig params"
  type = map
}

variable az2_tenantF5 {
  description = "Az2 tenantF5 baseConfig params"
  type = map
}

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

    #subnet gateways
    az1_mgmt_gw         = "${cidrhost(local.az1MgmtSnet, 1)}"
    az2_mgmt_gw         = "${cidrhost(local.az2MgmtSnet, 1)}"
    az1_tenant_ext_gw   = "${cidrhost(local.az1ExtSnet, 1)}"
    az2_tenant_ext_gw   = "${cidrhost(local.az2ExtSnet, 1)}"
    az1_tenant_int_gw   = "${cidrhost(local.az1IntSnet, 1)}"
    az2_tenant_int_gw   = "${cidrhost(local.az2IntSnet, 1)}"

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
    az1_cwLogStream   = "${var.tenant_name}-${var.az1_tenantF5.hostname}"
    az2_cwLogStream   = "${var.tenant_name}-${var.az2_tenantF5.hostname}"

    #CF
    tenant_cf_json    = "${var.tenant_name}_${var.tenant_cf_json}"
}

# F5 AnO extension vars
variable az1_tenantCluster_do_json { default = "tenantF5vm01.do.json" }
variable az2_tenantCluster_do_json { default = "tenantF5vm02.do.json" }
variable tenant1_paz_as3_json { default = "tenant1_pas.as3.json" }
variable tenant_ts_json { default = "tsCloudwatch_ts.json" }
variable tenant_logs_as3_json { default = "tsLogCollection_as3.json" }
variable tenant_cf_json { default = "tenant_cf.json" }

# F5 AnO Toolchain API Configuration
## Last updated: 1/19/2020
variable DO_onboard_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-declarative-onboarding-1.9.0-1.noarch.rpm" }
variable TS_URL { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.9.0/f5-telemetry-1.9.0-1.noarch.rpm"}
variable CF_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-cloud-failover-1.0.0-0.noarch.rpm" }
variable AS3_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-appsvcs-3.16.0-6.noarch.rpm" }

# F5 AnO REST API Settings
variable rest_tmsh_uri { default = "/mgmt/tm/util/bash" }
variable rest_do_uri { default = "/mgmt/shared/declarative-onboarding" }
variable rest_as3_uri { default = "/mgmt/shared/appsvcs/declare" }
variable rest_ts_uri { default = "/mgmt/shared/telemetry/declare" }
variable rest_cf_uri { default = "/mgmt/shared/cloud-failover/declare" }
variable rest_do_method { default = "POST" }
variable rest_as3_method { default = "POST" }
variable rest_ts_method { default = "POST" }
variable rest_cf_method { default = "POST" }
variable rest_util_method { default = "POST" }