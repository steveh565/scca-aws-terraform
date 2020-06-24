# Setup Onboarding scripts
data "template_file" "az1_pazF5_vm_onboard" {
  template = "${file("${path.module}/templates/onboard.tpl")}"

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL		     = var.AS3_URL
    TS_URL		     = var.TS_URL
    CF_URL		     = var.CF_URL
    libs_dir	     = var.libs_dir
    onboard_log	   = var.onboard_log

    mgmt_ip        = local.az1PazMgmtIp
    mgmt_gw        = local.az1_mgmt_gw
    vpc_dns        = local.vpc_dns
    dns_domain     = var.f5Domainname
    ext_self       = local.az1PazExtSelfIp
    int_self       = local.az1PazIntSelfIp
    gateway        = local.az1_paz_ext_gw

    aip_nexthop_cidr = var.aip_dmz_ext_cidr
    aip_tenants_vip_cidr = var.aip_tenants_vip_cidr
    internal_gw    = local.az1_paz_int_gw
    aip_nextHop_internal = local.aip_az1DmzExtFloatIp
  }
}

# Render Onboarding script
resource "local_file" "az1_pazF5_vm_onboarding_file" {
  content     = data.template_file.az1_pazF5_vm_onboard.rendered
  filename    = "${path.module}/files/${var.az1_pazF5_onboard_script}"
}


data "template_file" "az2_pazF5_vm_onboard" {
  template = "${file("${path.module}/templates/onboard.tpl")}"

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL		     = var.AS3_URL
    TS_URL		     = var.TS_URL
    CF_URL		     = var.CF_URL
    libs_dir	     = var.libs_dir
    onboard_log	   = var.onboard_log

    mgmt_ip        = local.az2PazMgmtIp
    mgmt_gw        = local.az2_mgmt_gw
    vpc_dns        = local.vpc_dns
    dns_domain     = var.f5Domainname
    ext_self       = local.az2PazExtSelfIp
    int_self       = local.az2PazIntSelfIp
    gateway        = local.az2_paz_ext_gw

    aip_nexthop_cidr = var.aip_dmz_ext_cidr
    aip_tenants_vip_cidr = var.aip_tenants_vip_cidr
    internal_gw    = local.az2_paz_int_gw
    aip_nextHop_internal = local.aip_az1DmzExtFloatIp
  }
}

# Render Onboarding script
resource "local_file" "az2_pazF5_vm_onboarding_file" {
  content     = data.template_file.az2_pazF5_vm_onboard.rendered
  filename    = "${path.module}/files/${var.az2_pazF5_onboard_script}"
}


# Setup Onboarding scripts
data "template_file" "az1_dmzF5_vm_onboard" {
  template = "${file("${path.module}/templates/onboard.tpl")}"

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL		     = var.AS3_URL
    TS_URL		     = var.TS_URL
    CF_URL		     = var.CF_URL
    libs_dir	     = var.libs_dir
    onboard_log	   = var.onboard_log

    mgmt_ip        = local.az1DmzMgmtIp
    mgmt_gw        = local.az1_mgmt_gw
    vpc_dns        = local.vpc_dns
    dns_domain     = var.f5Domainname
    ext_self       = local.az1DmzExtSelfIp
    int_self       = local.az1DmzIntSelfIp
    gateway        = local.az1_dmz_ext_gw

    aip_nexthop_cidr = var.aip_dmzTransit_ext_cidr
    aip_tenants_vip_cidr = var.aip_tenants_vip_cidr
    internal_gw    = local.az1_dmz_int_gw
    aip_nextHop_internal = local.aip_az1TransitExtFloatIp
  }
}

# Render Onboarding script
resource "local_file" "az1_dmzF5_vm_onboarding_file" {
  content     = data.template_file.az1_dmzF5_vm_onboard.rendered
  filename    = "${path.module}/files/${var.az1_dmzF5_onboard_script}"
}


data "template_file" "az2_dmzF5_vm_onboard" {
  template = "${file("${path.module}/templates/onboard.tpl")}"

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL		     = var.AS3_URL
    TS_URL		     = var.TS_URL
    CF_URL		     = var.CF_URL
    libs_dir	     = var.libs_dir
    onboard_log	   = var.onboard_log

    mgmt_ip        = local.az2DmzMgmtIp
    mgmt_gw        = local.az2_mgmt_gw
    vpc_dns        = local.vpc_dns
    dns_domain     = var.f5Domainname
    ext_self       = local.az2DmzExtSelfIp
    int_self       = local.az2DmzIntSelfIp
    gateway        = local.az2_dmz_ext_gw

    aip_nexthop_cidr = var.aip_dmzTransit_ext_cidr
    aip_tenants_vip_cidr = var.aip_tenants_vip_cidr
    internal_gw    = local.az2_dmz_int_gw
    aip_nextHop_internal = local.aip_az1TransitExtFloatIp
  }
}

# Render Onboarding script
resource "local_file" "az2_dmzF5_vm_onboarding_file" {
  content     = data.template_file.az2_dmzF5_vm_onboard.rendered
  filename    = "${path.module}/files/${var.az2_dmzF5_onboard_script}"
}


# Setup Onboarding scripts
data "template_file" "az1_transitF5_vm_onboard" {
  template = "${file("${path.module}/templates/onboard.tpl")}"

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL		     = var.AS3_URL
    TS_URL		     = var.TS_URL
    CF_URL		     = var.CF_URL
    libs_dir	     = var.libs_dir
    onboard_log	   = var.onboard_log

    mgmt_ip        = local.az1TransitMgmtIp
    mgmt_gw        = local.az1_mgmt_gw
    vpc_dns        = local.vpc_dns
    dns_domain     = var.f5Domainname
    ext_self       = local.az1TransitExtSelfIp
    int_self       = local.az1TransitIntSelfIp
    gateway        = local.az1_dmz_int_gw

    #Set these to NULL because transitF5 VE's don't need them
    aip_nexthop_cidr = ""
    aip_tenants_vip_cidr = ""
    internal_gw    = ""
    aip_nextHop_internal = ""
  }
}

# Render Onboarding script
resource "local_file" "az1_transitF5_vm_onboarding_file" {
  content     = data.template_file.az1_transitF5_vm_onboard.rendered
  filename    = "${path.module}/files/${var.az1_transitF5_onboard_script}"
}


data "template_file" "az2_transitF5_vm_onboard" {
  template = "${file("${path.module}/templates/onboard.tpl")}"

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL		     = var.AS3_URL
    TS_URL		     = var.TS_URL
    CF_URL		     = var.CF_URL
    libs_dir	     = var.libs_dir
    onboard_log	   = var.onboard_log

    mgmt_ip        = local.az2TransitMgmtIp
    mgmt_gw        = local.az2_mgmt_gw
    vpc_dns        = local.vpc_dns
    dns_domain     = var.f5Domainname
    ext_self       = local.az2TransitExtSelfIp
    int_self       = local.az2TransitIntSelfIp
    gateway        = local.az2_dmz_int_gw

    #Set these to NULL because transitF5 VE's don't need them
    aip_nexthop_cidr = ""
    aip_tenants_vip_cidr = ""
    internal_gw    = ""
    aip_nextHop_internal = ""
  }
}

# Render Onboarding script
resource "local_file" "az2_transitF5_vm_onboarding_file" {
  content     = data.template_file.az2_transitF5_vm_onboard.rendered
  filename    = "${path.module}/files/${var.az2_transitF5_onboard_script}"
}


# revokeLicenses scripts
data "template_file" "revokeLicenses" {
  template = file("${path.module}/templates/revokeLicenses.tpl")
  vars = {
    az1PazMgmt = aws_instance.az1_paz_bigip.public_ip
    az2PazMgmt = aws_instance.az2_paz_bigip.public_ip
    az1DmzMgmt = aws_instance.az1_dmz_bigip.public_ip
    az2DmzMgmt = aws_instance.az2_dmz_bigip.public_ip
    az1TransitMgmt = aws_instance.az1_transit_bigip.public_ip
    az2TransitMgmt = aws_instance.az2_transit_bigip.public_ip
    sshKey = var.key_path
  }
}

resource "local_file" "revokeLicenses_file" {
  content     = data.template_file.revokeLicenses.rendered
  filename    = "${path.module}/files/revokeLicenses.sh"
}