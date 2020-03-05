# Setup Onboarding scripts
data "template_file" "az1_tenantF5_vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL		   = var.AS3_URL
    TS_URL		   = var.TS_URL
    CF_URL		   = var.CF_URL
    libs_dir	   = var.libs_dir
    onboard_log	   = var.onboard_log

    mgmt_ip        = local.az1MgmtIp
    mgmt_gw        = local.az1_mgmt_gw
    vpc_dns        = local.vpc_dns
    ext_self       = local.az1ExtSelfIp
    int_self       = local.az1IntSelfIp
    gateway        = local.az1_tenant_ext_gw
  }
}

# Render Onboarding script
resource "local_file" "az1_tenantF5_vm_onboarding_file" {
  content     = data.template_file.az1_tenantF5_vm_onboard.rendered
  filename    = "${path.module}/${var.tenant_name}_${var.az1_tenantF5_onboard_script}"
}


data "template_file" "az2_tenantF5_vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL		     = var.AS3_URL
    TS_URL		     = var.TS_URL
    CF_URL		     = var.CF_URL
    libs_dir	     = var.libs_dir
    onboard_log	   = var.onboard_log

    mgmt_ip        = local.az2MgmtIp
    mgmt_gw        = local.az2_mgmt_gw
    vpc_dns        = local.vpc_dns
    ext_self       = local.az2ExtSelfIp
    int_self       = local.az2IntSelfIp
    gateway        = local.az2_tenant_ext_gw
  }
}

# Render Onboarding script
resource "local_file" "az2_tenantF5_vm_onboarding_file" {
  content     = data.template_file.az2_tenantF5_vm_onboard.rendered
  filename    = "${path.module}/${var.tenant_name}_${var.az2_tenantF5_onboard_script}"
}


# revokeLicenses scripts
data "template_file" "revokeLicenses" {
  template = file("${path.module}/revokeLicenses.tpl")
  vars = {
      az1Mgmt = aws_instance.az1_tenant_bigip.public_ip
      az2Mgmt = aws_instance.az2_tenant_bigip.public_ip
      sshKey = var.key_path
  }
}

resource "local_file" "revokeLicenses_file" {
  content     = data.template_file.revokeLicenses.rendered
  filename    = "${path.module}/${var.tenant_name}_revokeLicenses.sh"
}

