# ToDo: Update license keys
module securityStack {
  source = "./modules/securityStack"

  prefix = var.prefix
  tag_name = var.prefix

  security_vpc_cidr = "10.1.0.0/16"
  security_aip_cidr = "100.65.0.0/16"
  security_vpc_transit_aip_cidr = "100.65.5.0/29"

  aip_paz_dmz_ext_cidr    = "100.65.1.0/29"
  aip_dmz_ext_cidr        = "100.65.2.0/29"
  aip_dmz_int_cidr        = "100.65.3.0/29"
  aip_dmzTransit_ext_cidr = "100.65.4.0/29"
  aip_Transit_int_cidr    = "100.65.5.0/29"

  aip_tenants_cidr        = "100.66.64.0/21"
  aip_tenants_vip_cidr    = "100.100.0.0/16"
  
  uname = var.uname
  upassword = var.upassword

  ami_f5image_name = data.aws_ami.bigip_ami.id
  aws_region = var.aws_region

  az1_pazF5 = {
    "instance_type" = "c4.2xlarge"
    "license"       = "BFQEM-DDCIY-DIXHU-NXQGG-TUUBSRT"
    "hostname"      = "pazF5vm01"
  }

  az1_dmzF5 = {
    "instance_type"  = "c4.2xlarge"
    "license"        = "SREKD-LSZDA-CVWHC-SBZUD-SHYJDCP"
    "hostname"     = "dmzF5vm01"
  }

  az1_transitF5 = {
    "instance_type"  = "c4.2xlarge"
    "license"      = "WTNZV-WRFTB-GHCXF-VIKFJ-FILSZQE"
    "hostname"     = "transitF5vm01"
  }

  az2_pazF5  = {
    "instance_type"  = "c4.2xlarge"
    "license"      = "UAEWA-ZTTQX-INMCQ-PVSGO-FEOYNTC"
    "hostname"     = "pazF5vm02"
  }

  az2_dmzF5 = {
    "instance_type"  = "c4.2xlarge"
    "license"      = "WTBLS-JOKDP-QDHMG-NRSAW-JPKOJHR"
    "hostname"     = "dmzF5vm02"
  }

  az2_transitF5 = {
    "instance_type"  = "c4.2xlarge"
    "license"      = "FOQBV-GQRYG-UECAR-DGKCD-SNRYCOL"
    "hostname"     = "transitF5vm02"
  }
}
