# Input Variables
variable aws_region { description = "String: AWS region to deploy in" }

# Prefixes
variable prefix { default = "SHSCA" }
variable tenant_name { default = "Tenant" }
variable tag_name { description = "String: Globally unique object Tag value" }

variable ami_f5image_name { description = "String: A Valid F5 BigIP AMI ID for the target AWS region" }

#SSH public key path
variable key_path { default = "~/.ssh/id_rsa.pub" }

#Source IPv4 CIDR block(s) allowed to access management
variable mgmt_asrc { default = ["0.0.0.0/0"] }

# Platform settings variables
variable f5Domainname        { default = "f5labs.gc.ca" }

variable uname      { default = "awsops" }
variable upassword  { default = "Canada12345" }
variable ntp_server { default = "0.us.pool.ntp.org" }
variable timezone   { default = "UTC" }
variable libs_dir	  { default = "/config/cloud/aws/node_modules" }
variable onboard_log	{ default = "/var/log/startup-script.log" }

# Local Security groups
variable sgExternal { default = "sgExternal" }
variable sgExtMgmt { default = "sgExtMgmt" }
variable sgInternal { default = "sgInternal" }

# Security VPC information
variable security_vpc_cidr { description = "String: SecurityStack VPC CIDR" }
variable security_aip_cidr { description = "String: SecurityStack Alien-IP VPC CIDR" }
variable security_vpc_transit_aip_cidr { description = "String: SecurityStack VPC Transit::Internal Alien-IP CIDR" }

variable vpc_tgw_name { default = "hubTGW" }

variable aip_paz_dmz_ext_cidr     { description = "String: Alien-IP CIDR for pazF5 DMZ-Ext subnet" }
variable aip_dmz_ext_cidr         { description = "String: Alien-IP CIDR for dmzF5 DMZ-Ext subnet" }
variable aip_dmz_int_cidr         { description = "String: Alien-IP CIDR for dmzF5 DMZ-Int subnet" }
variable aip_dmzTransit_ext_cidr  { description = "String: Alien-IP CIDR for transitF5 DMZ-Int subnet" }
variable aip_Transit_int_cidr     { description = "String: Alien-IP CIDR for transitF5 Transit-Int subnet" }
variable aip_tenants_cidr         { description = "String: Alien-IP CIDR SuperScope for all tenants" }
variable aip_tenants_vip_cidr     { description = "String: Alien-IP CIDR SuperScope for all tenant VIPs" }

variable az1_pazF5 {
  description = "Az1 pazF5 baseConfig params"
  type = map
}

variable az1_dmzF5 {
  description = "Az1 dmzF5 baseConfig params"
  type = map
}

variable az1_transitF5 {
  description = "Az1 transitF5 baseConfig params"
  type = map
}

variable az2_pazF5 {
  description = "Az2 pazF5 baseConfig params"
  type = map
}

variable az2_dmzF5 {
  description = "Az2 dmzF5 baseConfig params"
  type = map
}

variable az2_transitF5 {
  description = "Az2 transitF5 baseConfig params"
  type = map
}

# Cloudwatch information
variable cwLogGroup { default = "f5telemetry" }

#derived values
locals {
    #VPC native subnets
    vpc_dns           = "${cidrhost(var.security_vpc_cidr, 2)}"
    az1MgmtSnet       = "${cidrsubnet(var.security_vpc_cidr, 8, 0)}"
    az2MgmtSnet       = "${cidrsubnet(var.security_vpc_cidr, 8, 10)}"

    az1PazExtSnet        = "${cidrsubnet(var.security_vpc_cidr, 8, 1)}"
    az2PazExtSnet        = "${cidrsubnet(var.security_vpc_cidr, 8, 11)}"

    az1DmzExtSnet        = "${cidrsubnet(var.security_vpc_cidr, 8, 2)}"
    az2DmzExtSnet        = "${cidrsubnet(var.security_vpc_cidr, 8, 12)}"
    az1DmzIntSnet        = "${cidrsubnet(var.security_vpc_cidr, 8, 3)}"
    az2DmzIntSnet        = "${cidrsubnet(var.security_vpc_cidr, 8, 13)}"

    az1TransitIntSnet        = "${cidrsubnet(var.security_vpc_cidr, 8, 4)}"
    az2TransitIntSnet        = "${cidrsubnet(var.security_vpc_cidr, 8, 14)}"

    # Alien-IP Subnets
    aipPazIntSnet     = var.aip_paz_dmz_ext_cidr
    aipDmzExtSnet     = var.aip_dmz_ext_cidr
    aipDmzIntSnet     = var.aip_dmz_int_cidr
    aipTransitExtSnet = var.aip_dmzTransit_ext_cidr
    aipTransitIntSnet = var.aip_Transit_int_cidr

    #subnet gateways
    az1_mgmt_gw      = "${cidrhost(local.az1MgmtSnet, 1)}"
    az2_mgmt_gw      = "${cidrhost(local.az2MgmtSnet, 1)}"

    az1_paz_ext_gw   = "${cidrhost(local.az1PazExtSnet, 1)}"
    az2_paz_ext_gw   = "${cidrhost(local.az2PazExtSnet, 1)}"
    az1_paz_int_gw   = "${cidrhost(local.az1DmzExtSnet, 1)}"
    az2_paz_int_gw   = "${cidrhost(local.az2DmzExtSnet, 1)}"

    az1_dmz_ext_gw   = "${cidrhost(local.az1DmzExtSnet, 1)}"
    az2_dmz_ext_gw   = "${cidrhost(local.az2DmzExtSnet, 1)}"
    az1_dmz_int_gw   = "${cidrhost(local.az1DmzIntSnet, 1)}"
    az2_dmz_int_gw   = "${cidrhost(local.az2DmzIntSnet, 1)}"

    az1_transit_ext_gw   = "${cidrhost(local.az1DmzIntSnet, 1)}"
    az2_transit_ext_gw   = "${cidrhost(local.az2DmzIntSnet, 1)}"
    az1_transit_int_gw   = "${cidrhost(local.az1TransitIntSnet, 1)}"
    az2_transit_int_gw   = "${cidrhost(local.az2TransitIntSnet, 1)}"

    #bigip addresses
    az1PazMgmtIp         = "${cidrhost(local.az1MgmtSnet, 11)}"
    az2PazMgmtIp         = "${cidrhost(local.az2MgmtSnet, 11)}"

    az1DmzMgmtIp         = "${cidrhost(local.az1MgmtSnet, 12)}"
    az2DmzMgmtIp         = "${cidrhost(local.az2MgmtSnet, 12)}"

    az1TransitMgmtIp     = "${cidrhost(local.az1MgmtSnet, 13)}"
    az2TransitMgmtIp     = "${cidrhost(local.az2MgmtSnet, 13)}"

    az1PazExtSelfIp      = "${cidrhost(local.az1PazExtSnet, 11)}"
    az1PazExtVipIp       = "${cidrhost(local.az1PazExtSnet, 111)}"
    az2PazExtSelfIp      = "${cidrhost(local.az2PazExtSnet, 11)}"
    az2PazExtVipIp       = "${cidrhost(local.az2PazExtSnet, 111)}"
    az1PazIntSelfIp      = "${cidrhost(local.az1DmzExtSnet, 11)}"
    az2PazIntSelfIp      = "${cidrhost(local.az2DmzExtSnet, 11)}"

    az1DmzExtSelfIp      = "${cidrhost(local.az1DmzExtSnet, 12)}"
    az2DmzExtSelfIp      = "${cidrhost(local.az2DmzExtSnet, 12)}"
    az1DmzExtVipIp       = "${cidrhost(local.az1DmzExtSnet, 112)}"
    az2DmzExtVipIp       = "${cidrhost(local.az2DmzExtSnet, 112)}"
    az1DmzIntSelfIp      = "${cidrhost(local.az1DmzIntSnet, 12)}"
    az2DmzIntSelfIp      = "${cidrhost(local.az2DmzIntSnet, 12)}"

    az1TransitExtSelfIp  = "${cidrhost(local.az1DmzIntSnet, 13)}"
    az2TransitExtSelfIp  = "${cidrhost(local.az2DmzIntSnet, 13)}"
    az1TransitExtVipIp   = "${cidrhost(local.az1DmzIntSnet, 113)}"
    az2TransitExtVipIp   = "${cidrhost(local.az2DmzIntSnet, 113)}"    
    az1TransitIntSelfIp  = "${cidrhost(local.az1TransitIntSnet, 13)}"
    az2TransitIntSelfIp  = "${cidrhost(local.az2TransitIntSnet, 13)}"

    aip_az1PazIntSelfIp  = "${cidrhost(local.aipPazIntSnet, 1)}"
    aip_az1PazIntFloatIp = "${cidrhost(local.aipPazIntSnet, 3)}"
    aip_az2PazIntSelfIp  = "${cidrhost(local.aipPazIntSnet, 2)}"
    
    aip_az1DmzExtSelfIp  = "${cidrhost(local.aipDmzExtSnet, 1)}"
    aip_az1DmzExtFloatIp = "${cidrhost(local.aipDmzExtSnet, 3)}"
    aip_az2DmzExtSelfIp  = "${cidrhost(local.aipDmzExtSnet, 2)}"

    aip_az1DmzIntSelfIp  = "${cidrhost(local.aipDmzIntSnet, 1)}"
    aip_az1DmzIntFloatIp = "${cidrhost(local.aipDmzIntSnet, 3)}"
    aip_az2DmzIntSelfIp  = "${cidrhost(local.aipDmzIntSnet, 2)}"

    aip_az1TransitExtSelfIp  = "${cidrhost(local.aipTransitExtSnet, 1)}"
    aip_az1TransitExtFloatIp = "${cidrhost(local.aipTransitExtSnet, 3)}"
    aip_az2TransitExtSelfIp  = "${cidrhost(local.aipTransitExtSnet, 2)}"

    aip_az1TransitIntSelfIp  = "${cidrhost(local.aipTransitIntSnet, 1)}"
    aip_az1TransitIntFloatIp = "${cidrhost(local.aipTransitIntSnet, 3)}"
    aip_az2TransitIntSelfIp  = "${cidrhost(local.aipTransitIntSnet, 2)}"

}

# F5 Onboarding Scripts
variable az1_pazF5_onboard_script { default = "az1_pazF5_onboard.sh" }
variable az2_pazF5_onboard_script { default = "az2_pazF5_onboard.sh" }
variable az1_dmzF5_onboard_script { default = "az1_dmzF5_onboard.sh" }
variable az2_dmzF5_onboard_script { default = "az2_dmzF5_onboard.sh" }
variable az1_transitF5_onboard_script { default = "az1_transitF5_onboard.sh" }
variable az2_transitF5_onboard_script { default = "az2_transitF5_onboard.sh" }

# Declarative-Onboarding extension Vars
variable az1_pazCluster_do_json { default = "pazF5vm01.do.json" }
variable az2_pazCluster_do_json { default = "pazF5vm02.do.json" }

variable az1_dmzCluster_do_json { default = "dmzF5vm01.do.json" }
variable az2_dmzCluster_do_json { default = "dmzF5vm02.do.json" }

variable az1_transitCluster_do_json { default = "transitF5vm01.do.json" }
variable az2_transitCluster_do_json { default = "transitF5vm02.do.json" }

# Telemetry Streaming externsion Vars
variable paz_ts_json { default = "paz_tsCloudwatch_ts.json" }
variable paz_logs_as3_json { default = "paz_tsLogCollection_as3.json" }
variable dmz_ts_json { default = "dmz_tsCloudwatch_ts.json" }
variable dmz_logs_as3_json { default = "dmz_tsLogCollection_as3.json" }
variable transit_ts_json { default = "transit_tsCloudwatch_ts.json" }
variable transit_logs_as3_json { default = "transit_tsLogCollection_as3.json" }

# Cloud-failover extension Vars
variable paz_cf_json { default = "paz_cf.json" }
variable dmz_cf_json { default = "dmz_cf.json" }
variable transit_cf_json { default = "transit_cf.json" }
variable maz_cf_json { default = "maz_cf.json" }

variable gccap_cf_label { default = "gccap-az-failover"}
variable paz_cf_label { default = "paz-az-failover" }
variable dmz_cf_label { default = "dmz-az-failover" }
variable transit_cf_label { default = "transit-az-failover" }

# AS3 extension Vars
variable asm_policy_url { default = "https://raw.githubusercontent.com/steveh565/f5tools/master/asm-policies/asm-policy-linux-medium.xml" }
variable paz_as3_json { default = "paz.as3.json" }
variable dmz_as3_json { default = "dmz.as3.json" }
variable transit_as3_json { default = "transit.as3.json" }

# F5 AnO Toolchain API Configuration
## Last updated: 1/19/2020
variable DO_onboard_URL { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.10.0/f5-declarative-onboarding-1.10.0-2.noarch.rpm" }
variable TS_URL { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.9.0/f5-telemetry-1.9.0-1.noarch.rpm" }
variable CF_URL { default = "https://github.com/f5devcentral/f5-cloud-failover-extension/releases/download/v1.0.0/f5-cloud-failover-1.0.0-0.noarch.rpm" }
variable AS3_URL { default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.17.1/f5-appsvcs-3.17.1-1.noarch.rpm" }

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

