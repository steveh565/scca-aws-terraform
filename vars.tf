# TF Vars
variable tfstate_s3Bucket { default = "tfSharedState" }
variable tfstate_dynamoLocksDb { default = "tfLocks" }

# AWS Creds
variable "SP" {
  type = map
  default = {
    access_key = "NULL"
    secret_key = "NULL"
  }
}

# Input Variables
variable aws_region { default = "ca-central-1" }


# Prefixes
variable prefix { default = "SHSCA9" }
variable tag_name { default = "SHSCA9" }
variable tenant_name { default = "CSD" }
variable maz_name { default = "MAZ" }


variable f5Domainname        { default = "f5labs.gc.ca" }

#SSH public key path
variable key_path { default = "~/.ssh/id_rsa.pub" }

#Source IPv4 CIDR block(s) allowed to access management
variable mgmt_asrc { default = ["0.0.0.0/0"] }

#Big-IP License Keys (BEST)
variable paz_lic1          {default = "ULMXM-VYNHO-FSNBE-JTPDK-MUSJYAZ"}
variable paz_lic2          {default = "PFLCY-ZWRAS-HBQMN-ORXAA-UXACRSL"}
variable transit_lic1      {default = "FBOQV-YPOLD-YTNCE-PYODT-ACDQWBX"}
variable transit_lic2      {default = "DWTWI-HPXCY-JWZKF-BGUKT-HSFMGUV"}
variable dmz_lic1          {default = "KVUFW-PBUBC-JUGZF-LFLNX-KLYDFOS"}
variable dmz_lic2          {default = "ULFVE-TLULT-XUJKW-IWDYB-NVQABYA"}
variable tenant_bigip_lic1 {default = "ZECCO-BGFXA-BKKPQ-BGZQK-EANKAAA"}
variable tenant_bigip_lic2 {default = "ONKOU-PWLNB-BHCCX-CEIFP-BGFCNYG"}
// Use the tenant_vars.auto.tfvars file to store the tenant and bigip specific values instead of above
// The MAZ values are already stored that way (see variable tenant_values below)
#variable maz_bigip_lic1    {default = ""}
#variable maz_bigip_lic1    {}
#variable maz_bigip_lic2    {}

# Platform settings variables
variable ami_f5image_name { default = "ami-038e6394d715e5eac" }
variable ami_f5image_type { default = "AllTwoBootLocations" }
variable ami_image_version { default = "latest" }

variable ami_maz_f5image_name { default = "ami-038e6394d715e5eac" }
variable ami_maz_f5image_type { default = "AllTwoBootLocations" }
variable ami_maz_image_version { default = "latest" }

variable ami_f5instance_type { default = "c4.2xlarge" }
variable ami_paz_f5instance_type { default = "c4.2xlarge" }
variable ami_dmz_f5instance_type { default = "c4.2xlarge" }
variable ami_transit_f5instance_type { default = "c4.2xlarge" }
variable ami_maz_f5instance_type { default = "c4.2xlarge" }
variable ami_tenant_f5instance_type { default = "c4.2xlarge" }

variable uname { default = "awsops" }
variable upassword { default = "Canada12345" }
variable dns_server { default = "8.8.8.8" }
variable ntp_server { default = "0.us.pool.ntp.org" }
#variable timezone   { default = "UTC" }
variable timezone   { default = "America/New_York" }
variable libs_dir   { default = "/config/cloud/aws/node_modules" }


variable az1_pazF5_onboard_script { default = "az1_pazF5_onboard.sh" }
variable az2_pazF5_onboard_script { default = "az2_pazF5_onboard.sh" }
variable az1_dmzF5_onboard_script { default = "az1_dmzF5_onboard.sh" }
variable az2_dmzF5_onboard_script { default = "az2_dmzF5_onboard.sh" }
variable az1_mazF5_onboard_script { default = "az1_mazF5_onboard.sh" }
variable az2_mazF5_onboard_script { default = "az2_mazF5_onboard.sh" }
variable az1_transitF5_onboard_script { default = "az1_transitF5_onboard.sh" }
variable az2_transitF5_onboard_script { default = "az2_transitF5_onboard.sh" }
variable az1_tenantF5_onboard_script { default = "az1_tenantF5_onboard.sh" }
variable az2_tenantF5_onboard_script { default = "az2_tenantF5_onboard.sh" }

variable onboard_log { default = "/var/log/startup-script.log" }

# Platform Provisioning
variable provision_ltm { default = "nominal" }
variable provision_avr { default = "nominal" }
variable provision_ilx { default = "nominal" }
variable provision_asm { default = "nominal" }
variable provision_afm { default = "nominal" }
variable provision_apm { default = "nominal" }

variable paz_f5provisioning { default = "ltm:nominal,asm:nominal,avr:nominal,ilx:nominal" }
variable dmz_f5provisioning { default = "ltm:nominal,afm:nominal,avr:nominal,ilx:nominal" }
variable trusted_f5provisioning { default = "ltm:nominal,afm:nominal,avr:nominal:ilx:nominal" }
variable tenant_f5provisioning { default = "ltm:nominal,afm:nominal,apm:nominal,avr:nominal" }
variable maz_f5provisioning { default = "ltm:nominal,apm:nominal,avr:nominal,ilx:nominal" }


# AWS Network Environment
variable vpc_tgw_name { default = "hubTGW" }

# security VPC Network
variable sgExternal { default = "sgExternal" }
variable sgExtMgmt { default = "sgExtMgmt" }
variable sgInternal { default = "sgInternal" }

variable security_vpc_cidr { default = "10.1.0.0/16" }
variable security_aip_cidr { default = "100.65.0.0/21" }

variable az1_security_subnets {
  type = map
  default = {
    "mgmt"    = "10.1.0.0/24"
    "paz_ext" = "10.1.1.0/24"
    "dmz_ext" = "10.1.2.0/24"
    "dmz_int" = "10.1.3.0/24"
    "transit" = "10.1.4.0/24"
    "aip_paz_dmz_ext" = "100.65.1.0/24"
    "aip_dmz_ext" = "100.65.2.0/24"
    "aip_dmz_int" = "100.65.3.0/24"
    "aip_dmzTransit_ext" = "100.65.4.0/24"
    "aip_Transit_int" = "100.65.5.0/24"
  }
}

variable gccap_cf_label { default = "gccap_az_failover"}

variable paz_cf_label { default = "paz-az-failover" }
variable dmz_cf_label { default = "dmz-az-failover" }
variable transit_cf_label { default = "transit-az-failover" }

variable az1_pazF5 {
  type = map
  default = {
    "hostname"     = "pazF5vm01"
    "mgmt"         = "10.1.0.11"
    "paz_ext_self" = "10.1.1.11"
    "paz_ext_vip"  = "10.1.1.111"
    "dmz_ext_self" = "10.1.2.11"
    "dmz_ext_vip"  = "10.1.2.111"
    "aip_dmz_ext_self"   = "100.65.1.1"
    "aip_dmz_ext_float"  = "100.65.1.3"
  }
}

variable az1_dmzF5 {
  type = map
  default = {
    "hostname"     = "dmzF5vm01"
    "mgmt"         = "10.1.0.12"
    "dmz_ext_self" = "10.1.2.12"
    "dmz_ext_vip"  = "10.1.2.112"
    "dmz_int_self" = "10.1.3.12"
    "dmz_int_vip"  = "10.1.3.112"
    "aip_dmz_ext_self" = "100.65.2.1"
    "aip_dmz_ext_vip"  = "100.65.2.3"
    "aip_dmz_int_self" = "100.65.3.1"
    "aip_dmz_int_vip"  = "100.65.3.3"
  }
}

variable az1_transitF5 {
  type = map
  default = {
    "hostname"     = "transitF5vm01"
    "mgmt"         = "10.1.0.13"
    "dmz_int_self" = "10.1.3.13"
    "dmz_int_vip"  = "10.1.3.113"
    "transit_self" = "10.1.4.13"
    "transit_vip"  = "10.1.4.113"
    "aip_dmz_int_self" = "100.65.4.1"
    "aip_dmz_int_vip"  = "100.65.4.3"
    "aip_transit_self" = "100.65.5.1"
    "aip_transit_vip"  = "100.65.5.3"
  }
}

variable az2_security_subnets {
  type = map
  default = {
    "mgmt"    = "10.1.10.0/24"
    "paz_ext" = "10.1.11.0/24"
    "dmz_ext" = "10.1.12.0/24"
    "dmz_int" = "10.1.13.0/24"
    "transit" = "10.1.14.0/24"
  }
}

variable az2_pazF5 {
  type = map
  default = {
    "hostname"     = "pazF5vm02"
    "mgmt"         = "10.1.10.11"
    "paz_ext_self" = "10.1.11.11"
    "paz_ext_vip"  = "10.1.11.111"
    "dmz_ext_self" = "10.1.12.11"
    "dmz_ext_vip"  = "10.1.12.111"
    "aip_dmz_ext_self"   = "100.65.1.2"
    "aip_dmz_ext_float"  = "100.65.1.3"    
  }
}

variable az2_dmzF5 {
  type = map
  default = {
    "hostname"     = "dmzF5vm02"
    "mgmt"         = "10.1.10.12"
    "dmz_ext_self" = "10.1.12.12"
    "dmz_ext_vip"  = "10.1.12.112"
    "dmz_int_self" = "10.1.13.12"
    "dmz_int_vip"  = "10.1.13.112"
    "aip_dmz_ext_self" = "100.65.2.2"
    "aip_dmz_ext_vip"  = "100.65.2.3"
    "aip_dmz_int_self" = "100.65.3.2"
    "aip_dmz_int_vip"  = "100.65.3.3"    
  }
}

variable az2_transitF5 {
  type = map
  default = {
    "hostname"     = "transitF5vm02"
    "mgmt"         = "10.1.10.13"
    "dmz_int_self" = "10.1.13.13"
    "dmz_int_vip"  = "10.1.13.113"
    "transit_self" = "10.1.14.13"
    "transit_vip"  = "10.1.14.113"
    "aip_dmz_int_self" = "100.65.4.2"
    "aip_dmz_int_vip"  = "100.65.4.3"
    "aip_transit_self" = "100.65.5.2"
    "aip_transit_vip"  = "100.65.5.3"    
  }
}


# remote mgmt VPC Network
variable maz_vpc_cidr { default = "10.11.0.0/16" }
variable maz_aip_cidr { default = "100.66.71.250/29" }
variable az1_maz_subnets {
  type = map
  default = {
    "mgmt"     = "10.11.0.0/24"
    "transit"  = "10.11.1.0/24"
    "internal" = "10.11.2.0/24"
  }
}

variable maz_cf_label { default = "maz-az-failover" }

variable az1_mazF5 {
  type = map
  default = {
    "hostname"      = "mazF5vm01"
    "mgmt"          = "10.11.0.11"
    "maz_ext_self"  = "10.11.1.11"
    "maz_ext_vip"   = "10.11.1.111"
    "maz_int_self" = "10.11.2.11"
    "maz_int_vip"  = "10.11.2.111"
    "aip_gre_ext_self"   = "100.66.71.241"
    "aip_gre_ext_float"  = "100.66.71.243"
  }
}

variable az2_maz_subnets {
  type = map
  default = {
    "mgmt"     = "10.11.10.0/24"
    "transit"  = "10.11.11.0/24"
    "internal" = "10.11.12.0/24"
  }
}

variable az2_mazF5 {
  type = map
  default = {
    "hostname"      = "mazF5vm02"
    "mgmt"          = "10.11.10.11"
    "maz_ext_self"  = "10.11.11.11"
    "maz_ext_vip"   = "10.11.11.111"
    "maz_int_self" = "10.11.12.11"
    "maz_int_vip"  = "10.11.12.111"
    "aip_gre_ext_self"   = "100.66.71.252"
    "aip_gre_ext_float"  = "100.66.71.253"
  }
}

# MAZ Variables
# This variables are easier to manipulate when defined with type = map(object)
# The corresponding values are specified/set in the tenant_vars.auto.tfvars file. 
variable tenant_values {
  description = "maz-related parameters"
  type        = map(object({
    vpc_cidr = string
    aip_cidr = string
    cf_label = string
    prefix_label = string
    az1 = map(any)
    az2 = map(any)
  }))
}

# Tenant 1 VPC Network
variable tenant_vpc_cidr { default = "10.21.0.0/16" }
variable tenant_aip_cidr { default = "100.66.71.240/29" }
variable tenant_prefix_label { default = "Tenant0" }

variable az1_tenant_subnets {
  type = map
  default = {
    "mgmt"     = "10.21.0.0/24"
    "transit"  = "10.21.1.0/24"
    "internal" = "10.21.2.0/24"
  }
}

variable tenant_cf_label { default = "tenant-az-failover" }
variable az1_tenantF5 {
  type = map
  default = {
    "hostname"      = "edgeF5vm01"
    "mgmt"          = "10.21.0.11"
    "tenant_ext_self"  = "10.21.1.11"
    "tenant_ext_vip"   = "10.21.1.111"
    "tenant_int_self" = "10.21.2.11"
    "tenant_int_vip"  = "10.21.2.111"
    "aip_gre_ext_self"   = "100.66.71.241"
    "aip_gre_ext_float"  = "100.66.71.243"
  }
}

variable az2_tenant_subnets {
  type = map
  default = {
    "mgmt"     = "10.21.10.0/24"
    "transit"  = "10.21.11.0/24"
    "internal" = "10.21.12.0/24"
  }
}

variable az2_tenantF5 {
  type = map
  default = {
    "hostname"      = "edgeF5vm02"
    "mgmt"          = "10.21.10.11"
    "tenant_ext_self"  = "10.21.11.11"
    "tenant_ext_vip"   = "10.21.11.111"
    "tenant_int_self" = "10.21.12.11"
    "tenant_int_vip"  = "10.21.12.111"
    "aip_gre_ext_self"   = "100.66.71.242"
    "aip_gre_ext_float"  = "100.66.71.243"
  }
}



# F5 AnO Toolchain API Configuration
## Last updated: 1/19/2020
## Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
variable DO_onboard_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-declarative-onboarding-1.9.0-1.noarch.rpm" }
## Please check and update the latest Telemetry Streaming from https://github.com/F5Networks/f5-telemetry-streaming/tree/master/dist
#variable TS_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-telemetry-1.8.0-1.noarch.rpm" }
## Ask Steve to add the TSv1.9 RPM asset to his f5tools repo!
variable TS_URL { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.9.0/f5-telemetry-1.9.0-1.noarch.rpm"}
## Please check and update the latest Cloud Failover from https://github.com/f5devcentral/f5-cloud-failover-extension
variable CF_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-cloud-failover-1.0.0-0.noarch.rpm" }
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
variable AS3_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-appsvcs-3.16.0-6.noarch.rpm" }



# Declarative-Onboarding extension Vars
variable az1_pazCluster_do_json { default = "pazF5vm01.do.json" }
variable az2_pazCluster_do_json { default = "pazF5vm02.do.json" }

variable az1_dmzCluster_do_json { default = "dmzF5vm01.do.json" }
variable az2_dmzCluster_do_json { default = "dmzF5vm02.do.json" }

variable az1_transitCluster_do_json { default = "transitF5vm01.do.json" }
variable az2_transitCluster_do_json { default = "transitF5vm02.do.json" }

variable az1_mazCluster_do_json { default = "mazF5vm01.do.json" }
variable az2_mazCluster_do_json { default = "mazF5vm02.do.json" }

variable az1_tenantCluster_do_json { default = "tenantF5vm01.do.json" }
variable az2_tenantCluster_do_json { default = "tenantF5vm02.do.json" }





# Telemetry Streaming externsion Vars
variable paz_ts_json { default = "tsCloudwatch_ts.json" }
variable paz_logs_as3_json { default = "tsLogCollection_as3.json" }
variable dmz_ts_json { default = "tsCloudwatch_ts.json" }
variable dmz_logs_as3_json { default = "tsLogCollection_as3.json" }
variable transit_ts_json { default = "tsCloudwatch_ts.json" }
variable transit_logs_as3_json { default = "tsLogCollection_as3.json" }

variable maz_ts_json { default = "tsCloudwatch_ts.json" }
variable maz_logs_as3_json { default = "tsLogCollection_as3.json" }

variable tenant_ts_json { default = "tsCloudwatch_ts.json" }
variable tenant_logs_as3_json { default = "tsLogCollection_as3.json" }

# Cloud-failover extension Vars
variable paz_cf_json { default = "paz_cf.json" }
variable dmz_cf_json { default = "dmz_cf.json" }
variable transit_cf_json { default = "transit_cf.json" }
variable maz_cf_json { default = "maz_cf.json" }
variable tenant_cf_json { default = "tenant_cf.json" }


# AS3 extension Vars
variable asm_policy_url { default = "https://raw.githubusercontent.com/steveh565/f5tools/master/asm-policies/asm-policy-linux-medium.xml" }
variable tenant1_paz_as3_json { default = "tenant1_pas.as3.json" }
variable maz_paz_as3_json { default = "maz_paz.as3.json" }
variable maz_as3_json { default = "maz.as3.json" }
variable dmz_as3_json { default = "dmz.as3.json" }
variable transit_as3_json { default = "transit.as3.json" }

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



