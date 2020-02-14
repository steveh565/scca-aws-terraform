#terraform {
#  backend "s3" {
#    bucket         = "shsca7-tfsharedstate"
#    key            = "global/s3/terraform.tfstate"
#    region         = "ca-central-1"
#    dynamodb_table = "shsca7-tflocks"
#    encrypt        = true
#  }
#}

# Infrastructure
provider "aws" {
	region = var.aws_region
	
}

# Setup Onboarding scripts
data "template_file" "az1_pazF5_vm_onboard" {
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

    mgmt_ip        = var.az1_pazF5.mgmt
    mgmt_gw        = local.az1_mgmt_gw
    vpc_dns        = local.security_vpc_dns
    ext_self       = var.az1_pazF5.paz_ext_self
    int_self       = var.az1_pazF5.dmz_ext_self
    gateway        = local.az1_paz_gw
  }
}

# Render Onboarding script
resource "local_file" "az1_pazF5_vm_onboarding_file" {
  content     = "${data.template_file.az1_pazF5_vm_onboard.rendered}"
  filename    = "${path.module}/${var.az1_pazF5_onboard_script}"
}


data "template_file" "az2_pazF5_vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname          = "${var.uname}"
    upassword      = "${var.upassword}"
    DO_onboard_URL = "${var.DO_onboard_URL}"
    AS3_URL		     = "${var.AS3_URL}"
    TS_URL		     = "${var.TS_URL}"
    CF_URL		     = "${var.CF_URL}"
    libs_dir	     = "${var.libs_dir}"
    onboard_log	   = "${var.onboard_log}"

    mgmt_ip        = "${var.az2_pazF5.mgmt}"
    mgmt_gw        = "${local.az2_mgmt_gw}"
    vpc_dns        = "${local.security_vpc_dns}"
    ext_self       = "${var.az2_pazF5.paz_ext_self}"
    int_self       = "${var.az2_pazF5.dmz_ext_self}"
    gateway        = "${local.az2_paz_gw}"
  }
}

# Render Onboarding script
resource "local_file" "az2_pazF5_vm_onboarding_file" {
  content     = "${data.template_file.az2_pazF5_vm_onboard.rendered}"
  filename    = "${path.module}/${var.az2_pazF5_onboard_script}"
}


# Setup Onboarding scripts
data "template_file" "az1_dmzF5_vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname          = "${var.uname}"
    upassword      = "${var.upassword}"
    DO_onboard_URL = "${var.DO_onboard_URL}"
    AS3_URL		     = "${var.AS3_URL}"
    TS_URL		     = "${var.TS_URL}"
    CF_URL		     = "${var.CF_URL}"
    libs_dir	     = "${var.libs_dir}"
    onboard_log	   = "${var.onboard_log}"

    mgmt_ip        = "${var.az1_dmzF5.mgmt}"
    mgmt_gw        = "${local.az1_mgmt_gw}"
    vpc_dns        = "${local.security_vpc_dns}"
    ext_self       = "${var.az1_dmzF5.dmz_ext_self}"
    int_self       = "${var.az1_dmzF5.dmz_int_self}"
    gateway        = "${local.az1_dmz_ext_gw}"
  }
}

# Render Onboarding script
resource "local_file" "az1_dmzF5_vm_onboarding_file" {
  content     = "${data.template_file.az1_dmzF5_vm_onboard.rendered}"
  filename    = "${path.module}/${var.az1_dmzF5_onboard_script}"
}


data "template_file" "az2_dmzF5_vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname          = "${var.uname}"
    upassword      = "${var.upassword}"
    DO_onboard_URL = "${var.DO_onboard_URL}"
    AS3_URL		     = "${var.AS3_URL}"
    TS_URL		     = "${var.TS_URL}"
    CF_URL		     = "${var.CF_URL}"
    libs_dir	     = "${var.libs_dir}"
    onboard_log	   = "${var.onboard_log}"

    mgmt_ip        = "${var.az2_dmzF5.mgmt}"
    mgmt_gw        = "${local.az2_mgmt_gw}"
    vpc_dns        = "${local.security_vpc_dns}"
    ext_self       = "${var.az2_dmzF5.dmz_ext_self}"
    int_self       = "${var.az2_dmzF5.dmz_int_self}"
    gateway        = "${local.az2_dmz_ext_gw}"
  }
}

# Render Onboarding script
resource "local_file" "az2_dmzF5_vm_onboarding_file" {
  content     = "${data.template_file.az2_dmzF5_vm_onboard.rendered}"
  filename    = "${path.module}/${var.az2_dmzF5_onboard_script}"
}


# Setup Onboarding scripts
data "template_file" "az1_transitF5_vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname          = "${var.uname}"
    upassword      = "${var.upassword}"
    DO_onboard_URL = "${var.DO_onboard_URL}"
    AS3_URL		     = "${var.AS3_URL}"
    TS_URL		     = "${var.TS_URL}"
    CF_URL		     = "${var.CF_URL}"
    libs_dir	     = "${var.libs_dir}"
    onboard_log	   = "${var.onboard_log}"

    mgmt_ip        = "${var.az1_transitF5.mgmt}"
    mgmt_gw        = "${local.az1_mgmt_gw}"
    vpc_dns        = "${local.security_vpc_dns}"
    ext_self       = "${var.az1_transitF5.dmz_int_self}"
    int_self       = "${var.az1_transitF5.transit_self}"
    gateway        = "${local.az1_dmz_int_gw}"
  }
}

# Render Onboarding script
resource "local_file" "az1_transitF5_vm_onboarding_file" {
  content     = "${data.template_file.az1_transitF5_vm_onboard.rendered}"
  filename    = "${path.module}/${var.az1_transitF5_onboard_script}"
}


data "template_file" "az2_transitF5_vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname          = "${var.uname}"
    upassword      = "${var.upassword}"
    DO_onboard_URL = "${var.DO_onboard_URL}"
    AS3_URL		     = "${var.AS3_URL}"
    TS_URL		     = "${var.TS_URL}"
    CF_URL		     = "${var.CF_URL}"
    libs_dir	     = "${var.libs_dir}"
    onboard_log	   = "${var.onboard_log}"

    mgmt_ip        = "${var.az2_transitF5.mgmt}"
    mgmt_gw        = "${local.az2_mgmt_gw}"
    vpc_dns        = "${local.security_vpc_dns}"
    ext_self       = "${var.az2_transitF5.dmz_int_self}"
    int_self       = "${var.az2_transitF5.transit_self}"
    gateway        = "${local.az2_dmz_int_gw}"
  }
}

# Render Onboarding script
resource "local_file" "az2_transitF5_vm_onboarding_file" {
  content     = "${data.template_file.az2_transitF5_vm_onboard.rendered}"
  filename    = "${path.module}/${var.az2_transitF5_onboard_script}"
}




locals {
    depends_on   = []
    az1_mgmt_gw  = "${cidrhost(var.az1_security_subnets.mgmt, 1)}"
    az2_mgmt_gw  = "${cidrhost(var.az2_security_subnets.mgmt, 1)}"
    az1_paz_gw   = "${cidrhost(var.az1_security_subnets.paz_ext, 1)}"
    az2_paz_gw   = "${cidrhost(var.az2_security_subnets.paz_ext, 1)}"

    az1_dmz_ext_gw   = "${cidrhost(var.az1_security_subnets.dmz_ext, 1)}"
    az2_dmz_ext_gw   = "${cidrhost(var.az2_security_subnets.dmz_ext, 1)}"
    az1_dmz_int_gw   = "${cidrhost(var.az1_security_subnets.dmz_int, 1)}"
    az2_dmz_int_gw   = "${cidrhost(var.az2_security_subnets.dmz_int, 1)}"

    az1_transit_ext_gw   = "${cidrhost(var.az1_security_subnets.dmz_int, 1)}"
    az2_transit_ext_gw   = "${cidrhost(var.az2_security_subnets.dmz_int, 1)}"
    az1_transit_int_gw   = "${cidrhost(var.az1_security_subnets.transit, 1)}"
    az2_transit_int_gw   = "${cidrhost(var.az2_security_subnets.transit, 1)}"

    security_vpc_dns     = "${cidrhost(var.security_vpc_cidr, 2)}"
    tenant_vpc_dns       = "${cidrhost(var.tenant_vpc_cidr, 2)}"
    maz_vpc_dns          = "${cidrhost(var.maz_vpc_cidr, 2)}"
}


/*
module "maz" {
  source = "./maz"
}
*/

module "storage-paz" {
  source = "./modules/storage"
  storage_label = var.paz_cf_label
}


resource "null_resource" "revoke_eval_keys_upon_destroy" {
  depends_on = [
    aws_route_table_association.az1_mgmt,
    aws_route_table_association.az2_mgmt,
    aws_route_table_association.az1_dmzInt,
    aws_route_table_association.az2_dmzInt,
    aws_route_table_association.az1_dmzExt,
    aws_route_table_association.az2_dmzExt,
    aws_route_table_association.az1_transit,
    aws_route_table_association.az2_transit,
    aws_route_table_association.az1_ext,
    aws_route_table_association.az2_ext,
    aws_key_pair.main,
    aws_route_table.MgmtRt,
    aws_route_table.PazRt,
    aws_route_table.TransitRt,
    aws_route_table.DmzIntRt,
    aws_route_table.DmzExtRt,
    aws_ec2_transit_gateway_vpc_attachment.hubTgwAttach,
    aws_ec2_transit_gateway_route_table.hubtgwRt,
    aws_ec2_transit_gateway.hubtgw,
    local_file.az1_pazF5_vm_onboarding_file,
    local_file.az2_pazF5_vm_onboarding_file,
    local_file.az2_transitF5_vm_onboarding_file,
    local_file.az1_dmzF5_vm_onboarding_file,
    local_file.az1_transitF5_vm_onboarding_file,
    local_file.az2_dmzF5_vm_onboarding_file,

    aws_instance.az1_bigip,
    aws_instance.az2_bigip,
    // aws_instance.az1_transit_bigip,
    // aws_instance.az2_transit_bigip,
    // aws_instance.az1_dmz_bigip,
    // aws_instance.az2_dmz_bigip,
    aws_eip.eip_az1_mgmt,
    aws_eip.eip_az1_external,
    aws_eip.eip_az2_mgmt,
    aws_eip.eip_az2_external,
    // aws_eip.eip_az1_transit_mgmt,
    // aws_eip.eip_az2_transit_mgmt,
    // aws_eip.eip_az1_dmz_mgmt,
    // aws_eip.eip_az2_dmz_mgmt,
    aws_internet_gateway.gw
  ]
  for_each = {
    mgmt_ip = aws_instance.az1_bigip.public_ip
    mgmt_ip1 = aws_instance.az2_bigip.public_ip
    // mgmt_ip2 = aws_instance.az1_dmz_bigip.public_ip
    // mgmt_ip3 = aws_instance.az2_dmz_bigip.public_ip
    // mgmt_ip4 = aws_instance.az1_transit_bigip.public_ip
    // mgmt_ip5 = aws_instance.az2_transit_bigip.public_ip
  }
  provisioner "remote-exec" {
    connection {
      host     = each.value
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = destroy
    inline = [
      "echo y | tmsh -q revoke sys license 2>/dev/null"
    ]
    on_failure = continue
  }
}


output "az1_pazF5_Mgmt_Addr"     { value = "${aws_instance.az1_bigip.public_ip}" }
output "az2_pazF5_Mgmt_Addr"     { value = "${aws_instance.az2_bigip.public_ip}" }

output "PAZ_Ingress_Public_EIP"   { value = "${aws_eip.eip_vip.public_ip}" }
output "az1_pazF5_self_eip" { value = "${aws_eip.eip_az1_external.public_ip}"}
output "az2_pazF5_self_eip" { value = "${aws_eip.eip_az2_external.public_ip}"}

// output "az1_dmzF5_Mgmt_Addr"     { value = "${aws_instance.az1_dmz_bigip.public_ip}" }
// output "az2_dmzF5_Mgmt_Addr"     { value = "${aws_instance.az2_dmz_bigip.public_ip}" }
// output "az1_dmzF5_secondary_VIP" { value = "${var.az1_dmzF5.dmz_ext_vip}" }
// output "az2_dmzF5_secondary_VIP" { value = "${var.az2_dmzF5.dmz_ext_vip}" }

// output "az1_transitF5_Mgmt_Addr"     { value = "${aws_instance.az1_transit_bigip.public_ip}" }
// output "az2_transitF5_Mgmt_Addr"     { value = "${aws_instance.az2_transit_bigip.public_ip}" }
// output "az1_transitF5_secondary_VIP" { value = "${var.az1_transitF5.transit_vip}" }
// output "az2_transitF5_secondary_VIP" { value = "${var.az2_transitF5.transit_vip}" }

output "Hub_Transit_Gateway_ID"  { value = "${aws_ec2_transit_gateway.hubtgw.id}" }
output "BigIP_IAM_Profile_ID" { value = "${aws_iam_instance_profile.bigip-failover-extension-iam-instance-profile.id}" }
