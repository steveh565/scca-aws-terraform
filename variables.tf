# Input Variables
variable aws_region { description = "String: AWS Region in which to deploy" }

# Prefixes
variable prefix { description = "String: Globally unique object name prefix label" }
variable maz_name { description = "String: Globally unique Management Access Zone identification label" }

#Source IPv4 CIDR block(s) allowed to access management
variable mgmt_asrc { description = "List: Source IP Access Control List" }

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


