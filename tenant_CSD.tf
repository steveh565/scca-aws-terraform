# ToDo: Update license keys
module tenantStack_CSD {
  source = "./modules/tenantStack"
  security_vpc_transit_aip_cidr = "100.65.5.0/29"
  key_path = var.key_path
  prefix = var.prefix
  tenant_prefix = "TENANT1"
  tenant_name   = "CSD"
  tenant_cf_label = "CSD_tenant_az_failover"
  tenant_vpc_cidr = "10.21.0.0/16"
  tenant_aip_cidr = "100.66.64.8/29"
  tenant_gre_cidr = "172.16.1.4/30"
  tenant_vip_cidr = "100.100.1.0/24"
  tgwId = module.securityStack.Hub_Transit_Gateway_ID
  f5Domainname = "csd.${var.f5Domainname}"
  uname = var.uname
  upassword = var.upassword
  mgmt_asrc = var.mgmt_asrc
  ami_f5image_name = data.aws_ami.bigip_ami.id
  aws_region = var.aws_region
  
  az1_tenantF5 = {
    instance_type  = "c4.2xlarge"
    license      = "PWTVO-UNMRP-RNRXP-NLCIU-JLNMNCS"
    hostname      = "edgeF5vm01"
  }

  az2_tenantF5 = {
    instance_type  = "c4.2xlarge"
    license      = "JRHCD-FCEZP-DLQQI-HZIXW-QAEXUXK"
    hostname      = "edgeF5vm02"
  }
  
}


# Configure Transit Tier with GRE to new tenantStack
resource "aws_route" "TransitRt_toTenantStack_CSD" {
  depends_on                = [module.securityStack]
  destination_cidr_block    = module.tenantStack_CSD.tenant_vpc_cidr
  route_table_id            = module.securityStack.TransitRt_ID
  transit_gateway_id        = module.securityStack.Hub_Transit_Gateway_ID  
}

resource "aws_ec2_transit_gateway_route" "TgwRt_toTenantStack_CSD" {
  depends_on                     = [module.securityStack]
  destination_cidr_block         = module.tenantStack_CSD.tenant_aip_cidr
  transit_gateway_route_table_id = module.securityStack.hubtgwRt_ID
  transit_gateway_attachment_id  = module.tenantStack_CSD.tenant_tgwAttach_ID
}


/*
resource "aws_route" "toSecurityStack_CSD" {
  depends_on                = [module.securityStack, module.tenantStack_CSD, aws_route.toTenantStack_CSD]
  route_table_id            = module.tenantStack_CSD.tenant_TransitRt_ID
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id        = module.securityStack.Hub_Transit_Gateway_ID  
}
*/


# Configure SecurityStack-TransitF5 with LOCAL_ONLY routes to new tenantStack-F5
resource "null_resource" "az1_routesToTenantStack_CSD" {
  depends_on = [module.securityStack, module.tenantStack_CSD]
  provisioner "remote-exec" {
    connection {
      host     = module.securityStack.az1_transitF5_Mgmt_Addr
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh create /net route /LOCAL_ONLY/aip_toTenant_CSD network ${module.tenantStack_CSD.tenant_aip_cidr} gw ${module.securityStack.az1_transit_int_gw}",
      "tmsh create /net route /LOCAL_ONLY/toTenant_CSD network ${module.tenantStack_CSD.tenant_vpc_cidr} gw ${module.securityStack.az1_transit_int_gw}"
    ]
    on_failure = continue
  }
}

resource "null_resource" "az2_routesToTenantStack_CSD" {
  depends_on = [module.securityStack, module.tenantStack_CSD]
  provisioner "remote-exec" {
    connection {
      host     = module.securityStack.az2_transitF5_Mgmt_Addr
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh create /net route /LOCAL_ONLY/aip_toTenant_CSD network ${module.tenantStack_CSD.tenant_aip_cidr} gw ${module.securityStack.az2_transit_int_gw}",
      "tmsh create /net route /LOCAL_ONLY/toTenant_CSD network ${module.tenantStack_CSD.tenant_vpc_cidr} gw ${module.securityStack.az2_transit_int_gw}"
    ]
    on_failure = continue
  }
}

# Configure SecurityStack-TransitF5 with GRE tunnel to new tenantStack-F5
resource "null_resource" "greToTenantStack_CSD" {
  depends_on = [module.securityStack, module.tenantStack_CSD, null_resource.az1_routesToTenantStack_CSD, null_resource.az2_routesToTenantStack_CSD]
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
  depends_on = [module.securityStack, module.tenantStack_CSD, null_resource.greToTenantStack_CSD]
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

# Configure SecurityStack-TransitF5 with Virtual Servers & Pool targeting new tenantStack-F5
resource "null_resource" "vips_toTenantStack_CSD" {
  depends_on = [module.securityStack, module.tenantStack_CSD, null_resource.greToSecurityStack_CSD]
  provisioner "remote-exec" {
    connection {
      host     = module.securityStack.az1_transitF5_Mgmt_Addr
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh create /ltm pool tenant_CSD_pool monitor gateway_icmp service-down-action reselect reselect-tries 3 members add { ${module.tenantStack_CSD.greSelfIp}:0 }",
      "tmsh create /net route toTenant_CSD_vips network ${module.tenantStack_CSD.tenant_vip_cidr} pool tenant_CSD_pool",
      "tmsh create /ltm virtual tenant_CSD_tcp_vs destination ${cidrhost(module.tenantStack_CSD.tenant_vip_cidr, 0)}:0 mask ${cidrnetmask(module.tenantStack_CSD.tenant_vip_cidr)} pool tenant_CSD_pool ip-protocol tcp translate-address disabled translate-port disabled source-address-translation { type none } vlans add { external } vlans-enabled",
      "tmsh create /ltm virtual tenant_CSD_https_vs destination ${cidrhost(module.tenantStack_CSD.tenant_vip_cidr, 0)}:443 mask ${cidrnetmask(module.tenantStack_CSD.tenant_vip_cidr)} pool tenant_CSD_pool ip-protocol tcp translate-address disabled translate-port disabled source-address-translation { type none } profiles add { /Common/http /Common/serverssl } vlans add { external } vlans-enabled"
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
  vlans_enabled = "greToSecurityStack"
}
