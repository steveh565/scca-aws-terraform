# ToDo: Update license keys
module securityStack {
  source = "./modules/securityStack"

  prefix = var.prefix
  tag_name = var.prefix

  security_vpc_cidr = "10.1.0.0/16"
  security_aip_cidr = "100.65.0.0/21"
  security_vpc_transit_aip_cidr = "100.65.5.0/29"

  aip_paz_dmz_ext_cidr    = "100.65.1.0/29"
  aip_dmz_ext_cidr        = "100.65.2.0/29"
  aip_dmz_int_cidr        = "100.65.3.0/29"
  aip_dmzTransit_ext_cidr = "100.65.4.0/29"
  aip_Transit_int_cidr    = "100.65.5.0/29"

  aip_tenants_cidr        = "100.66.64.0/21"
  
  uname = var.uname
  upassword = var.upassword

  az1_pazF5 = {
    "instance_type" = "c4.2xlarge"
    "license"       = "RDFMS-JUYWX-NDBAL-BRHVC-DRARPSA"
    "hostname"      = "pazF5vm01"
  }

  az1_dmzF5 = {
    "instance_type"  = "c4.2xlarge"
    "license"        = "JJOEF-MCJVG-WBSMM-JBAFJ-TDJDJWT"
    "hostname"     = "dmzF5vm01"
  }

  az1_transitF5 = {
    "instance_type"  = "c4.2xlarge"
    "license"      = "SOHXX-ITRFN-FLPOI-CLFBQ-YECVFVV"
    "hostname"     = "transitF5vm01"
  }

  az2_pazF5  = {
    "instance_type"  = "c4.2xlarge"
    "license"      = "LQKGM-IHMRL-ANZGM-QODVX-ZRBQYEV"
    "hostname"     = "pazF5vm02"
  }

  az2_dmzF5 = {
    "instance_type"  = "c4.2xlarge"
    "license"      = "FQIHY-YPPQS-FTOIQ-UKEYL-GZHAXPF"
    "hostname"     = "dmzF5vm02"
  }

  az2_transitF5 = {
    "instance_type"  = "c4.2xlarge"
    "license"      = "TYSNK-HHSJZ-USCES-QFFHP-JMJETOP"
    "hostname"     = "transitF5vm02"
  }
}
