# Input Variables
variable aws_region { description = "String: AWS Region in which to deploy" }

# Prefixes
variable prefix { description = "String: Globally unique object name prefix label" }
variable maz_name { description = "String: Globally unique Management Access Zone identification label" }

#Source IPv4 CIDR block(s) allowed to access management
variable mgmt_asrc { description = "List: Source IP Access Control List" }

/*
variable tag_name { description = "String: Globally unique object Tag value" }
variable tenant_name { description = "String: Globally unique Tenant label" }

#Big-IP vars
variable paz_f5provisioning { default = "ltm:nominal,asm:nominal,avr:nominal,ilx:nominal" }
variable dmz_f5provisioning { default = "ltm:nominal,afm:nominal,avr:nominal,ilx:nominal" }
variable transit_f5provisioning { default = "ltm:nominal,afm:nominal,avr:nominal:ilx:nominal" }
variable tenant_f5provisioning { default = "ltm:nominal,afm:nominal,apm:nominal,avr:nominal" }
variable maz_f5provisioning { default = "ltm:nominal,apm:nominal,avr:nominal,ilx:nominal" }

variable security_vpc_cidr { description = "String: SecurityStack VPC CIDR" }
variable security_aip_cidr { description = "String: SecurityStack Alien-IP VPC CIDR" }
variable security_vpc_transit_aip_cidr { description = "String: SecurityStack VPC Transit::Internal Alien-IP CIDR" }

variable aip_paz_dmz_ext_cidr     { description = "String: Alien-IP CIDR for pazF5 DMZ-Ext subnet" }
variable aip_dmz_ext_cidr         { description = "String: Alien-IP CIDR for dmzF5 DMZ-Ext subnet" }
variable aip_dmz_int_cidr         { description = "String: Alien-IP CIDR for dmzF5 DMZ-Int subnet" }
variable aip_dmzTransit_ext_cidr  { description = "String: Alien-IP CIDR for transitF5 DMZ-Int subnet" }
variable aip_Transit_int_cidr     { description = "String: Alien-IP CIDR for transitF5 Transit-Int subnet" }
*/

# DNS
variable f5Domainname        { description = "String: Fully Qualified Domain Name for the enviorment" }

#SSH public key path
variable key_path { description = "String: Path the Public SSH Key" }

variable uname { description = "Default Admin Username" }
variable upassword { description = "Password for Default Admin" }

variable dns_server { default = "169.254.169.253" }
variable ntp_server { default = "0.us.pool.ntp.org" }
variable timezone   { default = "UTC" }
variable libs_dir   { default = "/config/cloud/aws/node_modules" }

/*
# MAZ VPC Network
variable maz_vpc_cidr { default = "10.11.0.0/16" }
variable maz_aip_cidr { default = "100.66.71.250/29" }
variable az1_maz_subnets {
  description = "Az1 mazF5 baseConfig params"
  type = map(object({
    mgmt     = string
    transit  = string
    internal = string
  }))
}

variable maz_cf_label { default = "maz-az-failover" }

variable az1_mazF5 {
  description = "Az1 mazF5 baseConfig params"
  type = map(object({
    instance_type  = string
    license      = string
    hostname      = string
    mgmt          = string
    maz_ext_self  = string
    maz_ext_vip   = string
    maz_int_self = string
    maz_int_vip  = string
    aip_gre_ext_self   = string
    aip_gre_ext_float  = string
  }))
}

variable az2_maz_subnets {
  description = "Az1 mazF5 baseConfig params"
  type = map(object({
    mgmt     = string
    transit  = string
    internal = string
  }))
}

variable az2_mazF5 {
  description = "Az1 mazF5 baseConfig params"
  type = map(object({
    instance_type  = string
    license      = string
    hostname      = string
    mgmt          = string
    maz_ext_self  = string
    maz_ext_vip   = string
    maz_int_self = string
    maz_int_vip  = string
    aip_gre_ext_self   = string
    aip_gre_ext_float  = string
  }))
}

# Tenant 1 VPC Network

variable tenant_prefix { description = "String: Globally unique Tenant Prefix label" }
variable tenant_vpc_cidr { description = "String: Tenant VPC CIDR" }
variable tenant_aip_cidr { description = "String: Tenant Alien-IP CIDR" }
variable tenant_gre_cidr { description = "String: Tenant GRE Tunnel to Security VPC CIDR" }
variable tenant_cf_label { description = "String: Globally unique F5 CloudFailover Extension tenant label" }

variable tgwId { description = "String: SecurityStack Transit Gateway ID" }

variable az1_tenantF5 {
  description = "Az1 tenantF5 baseConfig params"
  type = map(object({
    instance_type  = string
    license      = string
    hostname      = string
  }))
}

variable az2_tenantF5 {
  description = "Az2 tenantF5 baseConfig params"
  type = map(object({
    instance_type  = string
    license      = string
    hostname      = string
  }))
}
*/

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

variable az1_mazCluster_do_json { default = "mazF5vm01.do.json" }
variable az2_mazCluster_do_json { default = "mazF5vm02.do.json" }

variable maz_ts_json { default = "tsCloudwatch_ts.json" }
variable maz_logs_as3_json { default = "tsLogCollection_as3.json" }

variable maz_paz_as3_json { default = "maz_paz.as3.json" }
variable maz_as3_json { default = "maz.as3.json" }


