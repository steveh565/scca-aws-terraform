# Infrastructure
provider "aws" {
	region = var.aws_region
}


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

# ToDo: Update license keys
module tenantStack_MAZ {
  source = "./modules/tenantStack"
  security_vpc_transit_aip_cidr = "100.65.5.0/29"
  key_path = var.key_path
  prefix = var.prefix
  tenant_prefix = "TENANT0"
  tenant_name   = "MAZ"
  tenant_cf_label = "tenant0_az_failover"
  tenant_vpc_cidr = "10.20.0.0/16"
  tenant_aip_cidr = "100.66.64.0/29"
  tenant_gre_cidr = "172.16.1.0/30"
  tenant_vip_cidr = "100.100.0.0/24"
  tgwId = module.securityStack.Hub_Transit_Gateway_ID
  f5Domainname = "maz.${var.f5Domainname}"
  uname = var.uname
  upassword = var.upassword
  mgmt_asrc = var.mgmt_asrc

  
  az1_tenantF5 = {
    instance_type  = "c4.2xlarge"
    license      = "PSMMA-PQDCU-MRGKC-HEFYT-MCCDTXA"
    hostname      = "edgeF5vm01"
  }

  az2_tenantF5 = {
    instance_type  = "c4.2xlarge"
    license      = "OFEWA-NRDAK-NCGDD-UDWSW-PMARVMY"
    hostname      = "edgeF5vm02"
  }

}

# ToDo: Update license keys
module tenantStack_CSD {
  source = "./modules/tenantStack"
  security_vpc_transit_aip_cidr = "100.65.5.0/29"
  key_path = var.key_path
  prefix = var.prefix
  tenant_prefix = "TENANT1"
  tenant_name   = "CSD"
  tenant_cf_label = "tenant1_az_failover"
  tenant_vpc_cidr = "10.21.0.0/16"
  tenant_aip_cidr = "100.66.64.8/29"
  tenant_gre_cidr = "172.16.1.4/30"
  tenant_vip_cidr = "100.100.1.0/24"
  tgwId = module.securityStack.Hub_Transit_Gateway_ID
  f5Domainname = "csd.${var.f5Domainname}"
  uname = var.uname
  upassword = var.upassword
  mgmt_asrc = var.mgmt_asrc

  
  az1_tenantF5 = {
    instance_type  = "c4.2xlarge"
    license      = "OKGUR-PCIZR-NNMSN-SGIXI-GTVRRVV"
    hostname      = "edgeF5vm01"
  }

  az2_tenantF5 = {
    instance_type  = "c4.2xlarge"
    license      = "CZOOM-KZJNK-FBMJS-DNVAG-PAPCIFM"
    hostname      = "edgeF5vm02"
  }
  
}



# Configure Transit Tier with GRE to new tenantStack
resource "aws_route" "toTenantStack_MAZ" {
  depends_on                = [module.securityStack]
  route_table_id            = module.securityStack.TransitRt_ID
  destination_cidr_block    = module.tenantStack_MAZ.tenant_vpc_cidr
  transit_gateway_id        = module.securityStack.Hub_Transit_Gateway_ID  
}

/*
resource "aws_route" "toSecurityStack_MAZ" {
  depends_on                = [module.securityStack, module.tenantStack_MAZ, aws_route.toTenantStack_MAZ]
  route_table_id            = module.tenantStack_MAZ.tenant_TransitRt_ID
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id        = module.securityStack.Hub_Transit_Gateway_ID  
}
*/

resource "null_resource" "greToTenantStack_MAZ" {
  depends_on = [module.tenantStack_MAZ]
  provisioner "remote-exec" {
    connection {
      host     = module.securityStack.az1_transitF5_Mgmt_Addr
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh create net tunnels tunnel greToTenant${module.tenantStack_MAZ.tenant_name} local-address ${module.tenantStack_MAZ.greTunRemAddr} profile gre remote-address ${module.tenantStack_MAZ.greTunLocAddr} traffic-group traffic-group-1",
      "tmsh create net self greToTenant${module.tenantStack_MAZ.tenant_name}_Float address ${module.tenantStack_MAZ.greNextHop}/30 vlan greToTenant${module.tenantStack_MAZ.tenant_name} traffic-group traffic-group-1"
    ]
    on_failure = continue
  }
}

# Configure new tenantStack with GRE to Transit Tier
resource "null_resource" "greToSecurityStack_MAZ" {
  depends_on = [module.tenantStack_MAZ]
  provisioner "remote-exec" {
    connection {
      host     = module.tenantStack_MAZ.az1_BigIP_mgmtAddr
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh create net tunnels tunnel greToSecurityStack local-address ${module.tenantStack_MAZ.greTunLocAddr} profile gre remote-address ${module.tenantStack_MAZ.greTunRemAddr} traffic-group traffic-group-1",
      "tmsh create net self greToSecurityStack_Float address ${module.tenantStack_MAZ.greSelfIp}/30 vlan greToSecurityStack traffic-group traffic-group-1"
    ]
    on_failure = continue
  }
}

# Deploy F5 SRA WebPortal configs to MAZ tenant BigIP
module "f5SraWebPortal_MAZ" { 
  source = "./modules/f5SraWebPortal"
  bigip_mgmt_public_ip = module.tenantStack_MAZ.az1_BigIP_mgmtAddr
  bigip_vip_private_ip = cidrhost(module.tenantStack_MAZ.tenant_vip_cidr, 1)
  ssh_target_ip = cidrhost(module.tenantStack_MAZ.az1_mgmt_subnet, 11)
  rest_as3_uri = var.rest_as3_uri
  uname = var.uname
  upassword  = var.upassword
}



# Configure Transit Tier with GRE to new tenantStack
resource "aws_route" "toTenantStack_CSD" {
  depends_on                = [module.securityStack]
  route_table_id            = module.securityStack.TransitRt_ID
  destination_cidr_block    = module.tenantStack_CSD.tenant_vpc_cidr
  transit_gateway_id        = module.securityStack.Hub_Transit_Gateway_ID  
}

/*
resource "aws_route" "toSecurityStack_CSD" {
  depends_on                = [module.securityStack, module.tenantStack_CSD, aws_route.toTenantStack_CSD]
  route_table_id            = module.tenantStack_CSD.tenant_TransitRt_ID
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id        = module.securityStack.Hub_Transit_Gateway_ID  
}
*/

resource "null_resource" "greToTenantStack_CSD" {
  depends_on = [module.tenantStack_CSD]
  provisioner "remote-exec" {
    connection {
      host     = module.securityStack.az1_transitF5_Mgmt_Addr
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh create net tunnels tunnel greToTenant${module.tenantStack_CSD.tenant_name} local-address ${module.tenantStack_CSD.greTunRemAddr} profile gre remote-address ${module.tenantStack_CSD.greTunLocAddr} traffic-group traffic-group-1",
      "tmsh create net self greToTenant${module.tenantStack_CSD.tenant_name}_Float address ${module.tenantStack_CSD.greNextHop}/30 vlan greToTenant${module.tenantStack_CSD.tenant_name} traffic-group traffic-group-1"
    ]
    on_failure = continue
  }
}

# Configure new tenantStack with GRE to Transit Tier
resource "null_resource" "greToSecurityStack_CSD" {
  depends_on = [module.tenantStack_CSD]
  provisioner "remote-exec" {
    connection {
      host     = module.tenantStack_CSD.az1_BigIP_mgmtAddr
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh create net tunnels tunnel greToSecurityStack local-address ${module.tenantStack_CSD.greTunLocAddr} profile gre remote-address ${module.tenantStack_CSD.greTunRemAddr} traffic-group traffic-group-1",
      "tmsh create net self greToSecurityStack_Float address ${module.tenantStack_CSD.greSelfIp}/30 vlan greToSecurityStack traffic-group traffic-group-1"
    ]
    on_failure = continue
  }
}

# Deploy F5 SRA WebPortal configs to CSD tenant BigIP
module "f5SraWebPortal_CSD" { 
  source = "./modules/f5SraWebPortal"
  bigip_mgmt_public_ip = module.tenantStack_CSD.az1_BigIP_mgmtAddr
  bigip_vip_private_ip = cidrhost(module.tenantStack_CSD.tenant_vip_cidr, 1)
  ssh_target_ip = cidrhost(module.tenantStack_CSD.az1_mgmt_subnet, 11)
  rest_as3_uri = var.rest_as3_uri
  uname = var.uname
  upassword  = var.upassword
}