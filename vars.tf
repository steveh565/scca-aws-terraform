# TF Vars
variable tfstate_s3Bucket { default = "tfSharedState" }
variable tfstate_dynamoLocksDb { default = "tfLocks" }

# AWS Creds
variable "SP" {
  type = "map"
  default = {
    access_key = "AKIAQL5QPPJL3CZT4CHM"
    secret_key = "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"
  }
}

# Input Variables
variable aws_region { default = "ca-central-1" }

# Prefixes
variable prefix	{   default = "SHSCA7" }
variable tag_name { default = "SHSCA7" }
variable tenant_name { default = "CSD" }
variable maz_name { default = "MAZ" }


#SSH public key path
variable key_path {  default     = "~/.ssh/id_rsa.pub" }

#Source IPv4 CIDR block(s) allowed to access management
variable mgmt_asrc {  default     = ["0.0.0.0/0"] }

#Big-IP License Keys (BEST)
variable paz_lic1          { default = "MFDMO-KRVNQ-WYAAS-QNUUZ-ZVJQCBU" }
variable paz_lic2          { default = "PPOEX-BNSAA-EFJOT-HATXH-RUXBDKL" }
variable transit_lic1      { default = "PQOPD-ZIGYD-DFEBA-GADVM-TLGLTCT" }
variable transit_lic2      { default = "XPHDC-NBZMA-VZBKK-OHZGX-AIVUNCO" }
variable dmz_lic1          { default = "VRFJA-WCENA-XJEFW-YNSZM-HOTGBWP" }
variable dmz_lic2          { default = "OHXTW-HXGIK-ODMYQ-OORVL-CMPUHLL" }
variable tenant_bigip_lic1 { default = "XDEJW-QHTBQ-PQSPH-IHJGS-HKENGYC" }
variable tenant_bigip_lic2 { default = "OHXTW-HXGIK-ODMYQ-OORVL-CMPUHLL" }
variable maz_bigip_lic1    { default = "QDCIC-SQHBC-EZZGL-SLMBB-NVICVES" }
variable maz_bigip_lic2    { default = "MBSSG-EKNFM-BXRXX-DYPPH-NNXNNVX" }


# Platform settings variables
variable ami_f5image_name  { default = "ami-038e6394d715e5eac" }
variable ami_f5image_type  { default = "AllTwoBootLocations" }
variable ami_image_version { default = "latest" }

variable ami_f5instance_type         { default = "m5.xlarge" }
variable ami_paz_f5instance_type     { default = "m5.xlarge" }
variable ami_dmz_f5instance_type     { default = "m5.xlarge" }
variable ami_transit_f5instance_type { default = "m5.xlarge" }
variable ami_ztsra_f5iinstance_type  { default = "m5.xlarge"}


variable uname      { default = "awsops" }
variable upassword  { default = "Canada12345" }
variable dns_server { default = "8.8.8.8" }
variable ntp_server { default = "0.us.pool.ntp.org" }
variable timezone   { default = "UTC" }
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
variable az1_security_subnets {
    type = "map"
    default = {
        "mgmt"    = "10.1.0.0/24"
        "paz_ext" = "10.1.1.0/24"
        "dmz_ext" = "10.1.2.0/24"
        "dmz_int" = "10.1.3.0/24"
        "transit" = "10.1.4.0/24"
    }
}

variable az1_pazF5 {
    type = "map"
    default = {
        "hostname" = "pazF5vm01"
        "mgmt"     = "10.1.0.11"
        "paz_ext_self" = "10.1.1.11"
        "paz_ext_vip"  = "10.1.1.111"        
        "dmz_ext_self" = "10.1.2.11"
        "dmz_ext_vip"  = "10.1.2.111"
    }
}

variable az1_dmzF5 {
    type = "map"
    default = {
        "hostname" = "dmzF5vm01"
        "mgmt"     = "10.1.0.12"
        "dmz_ext_self" = "10.1.2.12"
        "dmz_ext_vip"  = "10.1.2.112"        
        "dmz_int_self" = "10.1.3.12"
        "dmz_int_vip"  = "10.1.3.112"
    }
}

variable az1_transitF5 {
    type = "map"
    default = {
        "hostname" = "transitF5vm01"
        "mgmt"     = "10.1.0.13"
        "dmz_int_self"     = "10.1.3.13"
        "dmz_int_vip"      = "10.1.3.113"
        "transit_self" = "10.1.4.13"
        "transit_vip"  = "10.1.4.113"
    }
}

variable az2_security_subnets {
    type = "map"
    default = {
        "mgmt"    = "10.1.10.0/24"
        "paz_ext" = "10.1.11.0/24"
        "dmz_ext" = "10.1.12.0/24"
        "dmz_int" = "10.1.13.0/24"
        "transit" = "10.1.14.0/24"
    }
}

variable az2_pazF5 {
    type = "map"
    default = {
        "hostname" = "pazF5vm02"
        "mgmt"     = "10.1.10.11"
        "paz_ext_self" = "10.1.11.11"
        "paz_ext_vip"  = "10.1.11.111"        
        "dmz_ext_self" = "10.1.12.11"
        "dmz_ext_vip"  = "10.1.12.111"
    }
}

variable az2_dmzF5 {
    type = "map"
    default = {
        "hostname" = "dmzF5vm02"
        "mgmt"     = "10.1.10.12"
        "dmz_ext_self" = "10.1.12.12"
        "dmz_ext_vip"  = "10.1.12.112"        
        "dmz_int_self" = "10.1.13.12"
        "dmz_int_vip"  = "10.1.13.112"
    }
}

variable az2_transitF5 {
    type = "map"
    default = {
        "hostname" = "transitF5vm02"
        "mgmt"     = "10.1.10.13"
        "dmz_int_self"     = "10.1.13.13"
        "dmz_int_vip"      = "10.1.13.113"
        "transit_self" = "10.1.14.13"
        "transit_vip"  = "10.1.14.113"
    }
}


# remote mgmt VPC Network
variable ztsra_vpc_cidr    { default = "10.11.0.0/16" }
variable az1_ztsra_subnets {
    type = "map"
    default = {
        "mgmt"    = "10.11.0.0/24"
        "transit" = "10.11.1.0/24"
        "internal" = "10.11.2.0/24"
    }
}

variable az1_ztsra_transitF5 {
    type = "map"
    default = {
        "hostname" = "mazF5vm01"
        "mgmt"     = "10.11.0.11"
        "transit_self"  = "10.11.1.11"
        "transit_vip"   = "10.11.1.111"
        "internal_self" = "10.11.2.11"
        "internal_vip"  = "10.11.2.111"
    }
}

variable az2_ztsra_subnets {
    type = "map"
    default = {
        "mgmt"    = "10.11.10.0/24"
        "transit" = "10.11.11.0/24"
        "internal" = "10.11.12.0/24"
    }
}

variable az2_ztsra_transitF5 {
    type = "map"
    default = {
        "hostname" = "mazF5vm02"
        "mgmt"     = "10.11.10.11"
        "transit_self"  = "10.11.11.11"
        "transit_vip"   = "10.11.11.111"
        "internal_self" = "10.11.12.11"
        "internal_vip"  = "10.11.12.111"
    }
}

# Tenant 1 VPC Network
variable tenant_vpc_cidr    { default = "10.21.0.0/16" }
variable az1_tenant_subnets {
    type = "map"
    default = {
        "mgmt"    = "10.21.0.0/24"
        "transit" = "10.21.1.0/24"
        "internal" = "10.21.2.0/24"
    }
}

variable az1_tenant_transitF5 {
    type = "map"
    default = {
        "hostname" = "edgeF5vm01"
        "mgmt"     = "10.21.0.11"
        "transit_self"  = "10.21.1.11"
        "transit_vip"   = "10.21.1.111"
        "internal_self" = "10.21.2.11"
        "internal_vip"  = "10.21.2.111"
    }
}

variable az2_tenant_subnets {
    type = "map"
    default = {
        "mgmt"    = "10.21.10.0/24"
        "transit" = "10.21.11.0/24"
        "internal" = "10.21.12.0/24"
    }
}

variable az2_tenant_transitF5 {
    type = "map"
    default = {
        "hostname" = "edgeF5vm02"
        "mgmt"     = "10.21.10.11"
        "transit_self"  = "10.21.11.11"
        "transit_vip"   = "10.21.11.111"
        "internal_self" = "10.21.12.11"
        "internal_vip"  = "10.21.12.111"
    }
}



# F5 AnO Toolchain API Configuration
## Last updated: 1/19/2020
## Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
variable DO_onboard_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-declarative-onboarding-1.9.0-1.noarch.rpm" }
## Please check and update the latest Telemetry Streaming from https://github.com/F5Networks/f5-telemetry-streaming/tree/master/dist
variable TS_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-telemetry-1.8.0-1.noarch.rpm" }
## Please check and update the latest Cloud Failover from https://github.com/f5devcentral/f5-cloud-failover-extension
variable CF_URL { default = "https://github.com/f5devcentral/f5-cloud-failover-extension/releases/download/v0.9.1/f5-cloud-failover-0.9.1-1.noarch.rpm" }
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
variable AS3_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-appsvcs-3.16.0-6.noarch.rpm" }



# Declarative-Onboarding extension Vars
variable az1_pazBase_do_json { default = "pazF5_base_vm01.do.json" }
variable az2_pazBase_do_json { default = "pazF5_base_vm02.do.json" }
variable az1_pazCluster_do_json { default = "pazF5vm01.do.json" }
variable az2_pazCluster_do_json { default = "pazF5vm02.do.json" }
variable az1_paz_local_only_tmsh_json { default = "az1_paz_localOnly_tmsh.json" }
variable az2_paz_local_only_tmsh_json { default = "az2_paz_localOnly_tmsh.json" }

variable az1_dmzBase_do_json { default = "dmzF5_base_vm01.do.json" }
variable az2_dmzBase_do_json { default = "dmzF5_base_vm02.do.json" }
variable az1_dmzCluster_do_json { default = "dmzF5vm01.do.json" }
variable az2_dmzCluster_do_json { default = "dmzF5vm02.do.json" }
variable az1_dmz_local_only_tmsh_json { default = "az1_dmz_localOnly_tmsh.json" }
variable az2_dmz_local_only_tmsh_json { default = "az2_dmz_localOnly_tmsh.json" }

variable az1_transitBase_do_json { default = "transitF5_base_vm01.do.json" }
variable az2_transitBase_do_json { default = "transitF5_base_vm02.do.json" }
variable az1_transitCluster_do_json { default = "transitF5vm01.do.json" }
variable az2_transitCluster_do_json { default = "transitF5vm02.do.json" }
variable az1_transit_local_only_tmsh_json { default = "az1_dmz_localOnly_tmsh.json" }
variable az2_transit_local_only_tmsh_json { default = "az2_dmz_localOnly_tmsh.json" }

variable az1_mazBase_do_json { default = "mazF5_base_vm01.do.json" }
variable az2_mazBase_do_json { default = "mazF5_base_vm02.do.json" }
variable az1_mazCluster_do_json { default = "mazF5vm01.do.json" }
variable az2_mazCluster_do_json { default = "mazF5vm02.do.json" }
variable az1_maz_local_only_tmsh_json { default = "az1_maz_localOnly_tmsh.json" }
variable az2_maz_local_only_tmsh_json { default = "az2_maz_localOnly_tmsh.json" }

variable az1_tenantBase_do_json { default = "tenantF5_base_vm01.do.json" }
variable az2_tenantBase_do_json { default = "tenantF5_base_vm02.do.json" }
variable az1_tenantCluster_do_json { default = "tenantF5vm01.do.json" }
variable az2_tenantCluster_do_json { default = "tenantF5vm02.do.json" }
variable az1_tenant_local_only_tmsh_json { default = "az1_dmz_localOnly_tmsh.json" }
variable az2_tenant_local_only_tmsh_json { default = "az2_dmz_localOnly_tmsh.json" }




# Telemetry Streaming externsion Vars
variable paz_ts_json { default = "tsCloudwatch_ts.json" }
variable paz_logs_as3_json { default = "tsLogCollection_as3.json"}
variable dmz_ts_json { default = "tsCloudwatch_ts.json" }
variable dmz_logs_as3_json { default = "tsLogCollection_as3.json"}

# Cloud-failover extension Vars

# AS3 extension Vars
variable asm_policy_url { default = "https://raw.githubusercontent.com/steveh565/f5tools/master/asm-policies/asm-policy-linux-medium.xml" }
variable tenant1_paz_as3_json { default = "tenant1_pas.as3.json" }
variable maz_paz_as3_json { default = "maz_pas.as3.json" }
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


