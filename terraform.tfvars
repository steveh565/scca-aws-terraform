#Prefixes
prefix = "SHSCA1"
maz_name = "MAZ"

#AWS Region
aws_region = "ca-central-1"

# DNS
f5Domainname = "f5labs.gc.ca"

#SSH public key path
key_path = "~/.ssh/id_rsa.pub"

#Source IPv4 CIDR block(s) allowed to access management
mgmt_asrc = ["0.0.0.0/0"]

#Big-IP vars
uname     = "awsops"
upassword = "Canada12345"

# IP Network and Address assignments
/*
# MAZ VPC Network
maz_vpc_cidr = "10.10.0.0/16"
maz_aip_cidr = "100.66.71.250/29"

az1_maz_subnets = {
    "mgmt"     = "10.10.0.0/24"
    "transit"  = "10.10.1.0/24"
    "internal" = "10.10.2.0/24"
}


maz_cf_label = "maz-az-failover"

az1_mazF5 = {
    "instance_type"  = "c4.2xlarge"
    "license"      = "TWVDT-KDUER-FNPTP-OIBWQ-UIFHGQD"
    "hostname"      = "mazF5vm01"
    "mgmt"          = "10.10.0.11"
    "maz_ext_self"  = "10.10.1.11"
    "maz_ext_vip"   = "10.10.1.111"
    "maz_int_self" = "10.10.2.11"
    "maz_int_vip"  = "10.10.2.111"
    "aip_gre_ext_self"   = "100.66.71.241"
    "aip_gre_ext_float"  = "100.66.71.243"
}

az2_maz_subnets = {
    "mgmt"     = "10.10.10.0/24"
    "transit"  = "10.10.11.0/24"
    "internal" = "10.10.12.0/24"
}

az2_mazF5 = {
    "instance_type"  = "c4.2xlarge"
    "license"      = "MKQTG-IZKUU-OTWXX-QMVKA-CJEGHPF"
    "hostname"      = "mazF5vm02"
    "mgmt"          = "10.10.10.10"
    "maz_ext_self"  = "10.10.11.11"
    "maz_ext_vip"   = "10.10.11.111"
    "maz_int_self" = "10.10.12.11"
    "maz_int_vip"  = "10.10.12.111"
    "aip_gre_ext_self"   = "100.66.71.252"
    "aip_gre_ext_float"  = "100.66.71.253"
}
*/
# Tenant 1 VPC Network

