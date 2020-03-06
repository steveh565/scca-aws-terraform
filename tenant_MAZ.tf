# ToDo: Update license keys
module tenantStack_MAZ {
  source = "./modules/tenantStack"
  security_vpc_transit_aip_cidr = "100.65.5.0/29"
  key_path = var.key_path
  prefix = var.prefix
  tenant_prefix = "TENANT0"
  tenant_name   = "MAZ"
  tenant_cf_label = "MAZ_tenant_az_failover"
  tenant_vpc_cidr = "10.20.0.0/16"
  tenant_aip_cidr = "100.66.64.0/29"
  tenant_gre_cidr = "172.16.1.0/30"
  tenant_vip_cidr = "100.100.0.0/24"
  tgwId = module.securityStack.Hub_Transit_Gateway_ID
  f5Domainname = "maz.${var.f5Domainname}"
  uname = var.uname
  upassword = var.upassword
  mgmt_asrc = var.mgmt_asrc
  ami_f5image_name = data.aws_ami.bigip_ami.id
  aws_region = var.aws_region
  
  az1_tenantF5 = {
    instance_type  = "c4.2xlarge"
    license      = "FULKR-YEBDS-XPZCO-PHOQT-VSSRHNP"
    hostname      = "edgeF5vm01"
  }

  az2_tenantF5 = {
    instance_type  = "c4.2xlarge"
    license      = "DTMSM-GVKJQ-RBJND-CREWH-DBGLELS"
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

resource "aws_ec2_transit_gateway_route" "TgwRt_toTenantStack_MAZ" {
  depends_on                     = [module.securityStack]
  destination_cidr_block         = module.tenantStack_MAZ.tenant_aip_cidr
  transit_gateway_route_table_id = module.securityStack.hubtgwRt_ID
  transit_gateway_attachment_id  = module.tenantStack_MAZ.tenant_tgwAttach_ID
}

/*
resource "aws_route" "toSecurityStack_MAZ" {
  depends_on                = [module.securityStack, module.tenantStack_MAZ, aws_route.toTenantStack_MAZ]
  route_table_id            = module.tenantStack_MAZ.tenant_TransitRt_ID
  destination_cidr_block    = "0.0.0.0/0"
  transit_gateway_id        = module.securityStack.Hub_Transit_Gateway_ID  
}
*/

# Configure SecurityStack-TransitF5 with LOCAL_ONLY routes to new tenantStack-F5
resource "null_resource" "az1_routesToTenantStack_MAZ" {
  depends_on = [module.securityStack, module.tenantStack_MAZ]
  provisioner "remote-exec" {
    connection {
      host     = module.securityStack.az1_transitF5_Mgmt_Addr
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh create /net route /LOCAL_ONLY/aip_toTenant_MAZ network ${module.tenantStack_MAZ.tenant_aip_cidr} gw ${module.securityStack.az1_transit_int_gw}",
      "tmsh create /net route /LOCAL_ONLY/toTenant_MAZ network ${module.tenantStack_MAZ.tenant_vpc_cidr} gw ${module.securityStack.az1_transit_int_gw}"
    ]
    on_failure = continue
  }
}

resource "null_resource" "az2_routesToTenantStack_MAZ" {
  depends_on = [module.securityStack, module.tenantStack_MAZ]
  provisioner "remote-exec" {
    connection {
      host     = module.securityStack.az2_transitF5_Mgmt_Addr
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh create /net route /LOCAL_ONLY/aip_toTenant_MAZ network ${module.tenantStack_MAZ.tenant_aip_cidr} gw ${module.securityStack.az2_transit_int_gw}",
      "tmsh create /net route /LOCAL_ONLY/toTenant_MAZ network ${module.tenantStack_MAZ.tenant_vpc_cidr} gw ${module.securityStack.az2_transit_int_gw}"
    ]
    on_failure = continue
  }
}


# Configure SecurityStack-TransitF5 with GRE tunnel to new tenantStack-F5
resource "null_resource" "greToTenantStack_MAZ" {
  depends_on = [module.securityStack, module.tenantStack_MAZ]
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
  depends_on = [module.securityStack, module.tenantStack_MAZ]
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

# Configure SecurityStack-TransitF5 with Virtual Servers & Pool targeting new tenantStack-F5
resource "null_resource" "vips_toTenantStack_MAZ" {
  depends_on = [module.securityStack, module.tenantStack_MAZ, null_resource.greToSecurityStack_MAZ]
  provisioner "remote-exec" {
    connection {
      host     = module.securityStack.az1_transitF5_Mgmt_Addr
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh create /ltm pool tenant_MAZ_pool monitor gateway_icmp service-down-action reselect reselect-tries 3 members add { ${module.tenantStack_MAZ.greSelfIp}:0 }",
      "tmsh create /net route toTenant_MAZ_vips network ${module.tenantStack_MAZ.tenant_vip_cidr} pool tenant_MAZ_pool",
      "tmsh create /ltm virtual tenant_MAZ_tcp_vs destination ${cidrhost(module.tenantStack_MAZ.tenant_vip_cidr, 0)}:0 mask ${cidrnetmask(module.tenantStack_MAZ.tenant_vip_cidr)} pool tenant_MAZ_pool ip-protocol tcp translate-address disabled translate-port disabled source-address-translation { type none } vlans add { external } vlans-enabled",
      "tmsh create /ltm virtual tenant_MAZ_https_vs destination ${cidrhost(module.tenantStack_MAZ.tenant_vip_cidr, 0)}:443 mask ${cidrnetmask(module.tenantStack_MAZ.tenant_vip_cidr)} pool tenant_MAZ_pool ip-protocol tcp translate-address disabled translate-port disabled source-address-translation { type none } profiles add { /Common/http /Common/serverssl } vlans add { external } vlans-enabled"
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
  uname = var.uname
  upassword  = var.upassword
  #vlans_enabled = "/Common/greToSecurityStack"

  juiceshop_vip_private_ip = cidrhost(module.tenantStack_MAZ.tenant_vip_cidr, 2)
  juiceShop1 = module.tenantStack_MAZ.az1_juiceShop
  juiceShop2 = module.tenantStack_MAZ.az2_juiceShop
}
