# TF Vars
variable tfstate_s3Bucket { default = "tfSharedState" }
variable tfstate_dynamoLocksDb { default = "tfLocks" }

# REST API Settings
variable rest_do_uri { default = "/mgmt/shared/declarative-onboarding" }
variable rest_as3_uri { default = "/mgmt/shared/appsvcs/declare" }
variable rest_ts_uri { default = "/mgmt/shared/telemetry/declare" }
variable rest_do_method { default = "POST" }
variable rest_as3_method { default = "POST" }
variable rest_bigip_do_file { default = "bigip_do_data.json" }
variable rest_f5vm01_do_file { default = "f5vm01_do_data.json" }
variable rest_f5vm02_do_file { default = "f5vm02_do_data.json" }
variable rest_fwvm01_do_file { default = "fwvm01_do_data.json" }
variable rest_fwvm02_do_file { default = "fwvm02_do_data.json" }
variable rest_fwvm_as3_file { default = "fwvm_as3_data.json" }
variable rest_vm_ts_file { default = "ts.json" }
variable rest_vm_as3_file { default = "bigip_as3.json" }
## Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
variable DO_onboard_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-declarative-onboarding-1.7.0-3.noarch.rpm" }
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
variable AS3_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-appsvcs-3.14.0-4.noarch.rpm" }
## Please check and update the latest Telemetry Streaming from https://github.com/F5Networks/f5-telemetry-streaming/tree/master/dist
variable TS_URL { default = "https://github.com/steveh565/f5tools/raw/master/f5-telemetry-1.5.0-1.noarch.rpm" }
## Please check and update the latest Cloud Failover from https://github.com/f5devcentral/f5-cloud-failover-extension
variable CF_URL { default = "https://github.com/f5devcentral/f5-cloud-failover-extension/releases/download/v0.9.1/f5-cloud-failover-0.9.1-1.noarch.rpm" }

# Input Variables
variable "aws_region" {
  description = "AWS region"
  default     = "ca-central-1"
}

variable "tag_name" {
  description = "VPC Name tag"
  default     = "SHSCA5"
}


variable "key_path" {
  description = "SSH public key path"
  default     = "/home/steveh/.ssh/id_rsa.pub"
}

variable "mgmt_asrc" {
  description = "Source IPv4 CIDR block(s) allowed to access management"
  default     = ["0.0.0.0/0"]
}

variable "bigip_cft" {
  description = "BIG-IP CloudFormation template"
  default     = "https://s3.amazonaws.com/f5-cft/f5-existing-stack-across-az-cluster-byol-3nic-bigip.template"
}

variable "bigip_lic1" {
  description = "BIG-IP1 Registration Key"
  default     = "KTNMQ-JGDUE-YGPMF-FFBFB-QPQRPEY"
}

variable "bigip_lic2" {
  description = "BIG-IP2 Registration Key"
  default     = "SIDHT-JZZDS-XSAVY-EWBNS-OLPTMFK"
}

variable "bigip_lic3" {
  description = "BIG-IP3 Registration Key"
  default     = "GOSWC-XYFEU-XJFXC-WHPOI-XFVGPGY"
}

variable "bigip_lic4" {
  description = "BIG-IP4 Registration Key"
  default     = "HSXXU-EJHAT-YCZUG-YASDQ-BORTWDS"
}

variable "firewall_lic1" {
  description = "BIG-IP Firewall-1 Registration Key"
  default     = "VWQLU-IVKYK-LJKST-YHICZ-JIEILYN"
}

variable "firewall_lic2" {
  description = "BIG-IP Firewall-2 Registration Key"
  default     = "CCCKM-GYBEQ-CNKCZ-UJKAO-OJKMUXW"
}

variable "tenant_name" {
  description = "Default Tenant Name"
  default     = "Tenant1"
}

variable "tenant_bigip_lic1" {
  description = "BIG-IP1 Registration Key"
  default     = "KZBIP-ABHUK-GKAJX-FLQEJ-SACARSD"
}

variable "tenant_bigip_lic2" {
  description = "BIG-IP2 Registration Key"
  default     = "FTDKR-QWUOV-UMCDJ-NZTPF-HFDFSII"
}

variable "maz_bigip_lic1" {
  description = "BIG-IP1 Registration Key"
  default     = "FFQMY-FYNUT-FFZID-QVZOQ-LBSAWOW"
}

variable "maz_bigip_lic2" {
  description = "BIG-IP2 Registration Key"
  default     = "CKTTI-YAWJW-USCHP-CSVIH-KBOSQTK"
}


# Platform settings variables

variable uname { default = "admin" }
variable upassword { default = "Canada12345" }
variable dns_server { default = "8.8.8.8" }
variable ntp_server { default = "0.us.pool.ntp.org" }
variable timezone { default = "UTC" }
variable libs_dir { default = "/config/cloud/aws/node_modules" }
variable onboard_script { default = "onboard.sh" }
variable onboard_log { default = "/var/log/startup-script.log" }
variable paz_f5provisioning { default = "ltm:nominal,asm:nominal,avr:nominal,ilx:nominal" }
variable dmz_f5provisioning { default = "ltm:nominal,afm:nominal,avr:nominal,ilx:nominal" }
variable trusted_f5provisioning { default = "ltm:nominal,afm:nominal,avr:nominal:ilx:nominal" }
variable tenant_f5provisioning { default = "ltm:nominal,afm:nominal,apm:nominal,avr:nominal" }
variable maz_f5provisioning { default = "ltm:nominal,apm:nominal,avr:nominal,ilx:nominal" }


variable vpc_tgw_name { default = "hubTGW" }

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR block"
  default     = "10.200.0.0/16"
}

variable "mgmt1_cidr" {
  description = "Management subnet IPv4 CIDR block in AZ1"
  default     = "10.200.113.0/24"
}

variable "mgmt2_cidr" {
  description = "Management subnet IPv4 CIDR block in AZ2"
  default     = "10.200.123.0/24"
}

variable "ext1_cidr" {
  description = "External subnet IPv4 CIDR block in AZ1"
  default     = "10.200.115.0/24"
}

variable "ext2_cidr" {
  description = "External subnet IPv4 CIDR block in AZ2"
  default     = "10.200.125.0/24"
}

# DMZ Subnet CIDR blocks
variable dmzMgmt1_cidr { default = "10.200.1.0/24" }
variable dmzMgmt2_cidr { default = "10.200.11.0/24" }
variable dmzExt1_cidr { default = "10.200.2.0/24" }
variable dmzExt2_cidr { default = "10.200.21.0/24" }
variable dmzInt1_cidr { default = "10.200.3.0/24" }
variable dmzInt2_cidr { default = "10.200.31.0/24" }

# Trusted Subnet CIDR Blocks
variable trustedMgmt1_cidr { default = "10.200.21.0/24" }
variable trustedMgmt2_cidr { default = "10.200.201.0/24" }
variable trustedExt1_cidr { default = "10.200.22.0/24" }
variable trustedExt2_cidr { default = "10.200.202.0/24" }
variable trustedInt1_cidr { default = "10.200.23.0/24" }
variable trustedInt2_cidr { default = "10.200.203.0/24" }

# MAZ VPC and Subnet CIDR blocks
variable maz_vpc_cidr { default = "10.10.0.0/16" }
variable maz_mgmt1_cidr { default = "10.10.1.0/24" }
variable maz_mgmt2_cidr { default = "10.10.101.0/24" }
variable maz_ext1_cidr { default = "10.10.2.0/24" }
variable maz_ext2_cidr { default = "10.10.102.0/24" }
variable maz_int1_cidr { default = "10.10.3.0/24" }
variable maz_int2_cidr { default = "10.10.103.0/24" }
variable maz_name { default = "MAZ" }

# Tenant VPC and Subnet CIDR blocks
variable tenant_vpc_cidr { default = "10.70.0.0/16" }
variable tenant_mgmt1_cidr { default = "10.70.1.0/24" }
variable tenant_mgmt2_cidr { default = "10.70.101.0/24" }
variable tenant_ext1_cidr { default = "10.70.2.0/24" }
variable tenant_ext2_cidr { default = "10.70.102.0/24" }
variable tenant_int1_cidr { default = "10.70.3.0/24" }
variable tenant_int2_cidr { default = "10.70.103.0/24" }



# AS3 Vars
variable asm_policy_url { default = "https://raw.githubusercontent.com/steveh565/f5tools/master/asm-policies/asm-policy-linux-medium.xml" }
variable tenant1_paz_as3_json { default = "tenant1_pas.as3.json" }
variable maz_paz_as3_json { default = "maz_pas.as3.json" }
variable dmz_as3_json { default = "dmz.as3.json" }
variable trusted_as3_json { default = "trusted.as3.json" }
