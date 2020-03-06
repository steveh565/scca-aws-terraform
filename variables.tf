# Input Variables
variable aws_region { description = "String: AWS Region in which to deploy" }

# Prefixes
variable prefix { description = "String: Globally unique object name prefix label" }

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
