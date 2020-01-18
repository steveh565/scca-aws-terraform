#terraform {
#  backend "s3" {
#    bucket         = "shsca5-tfsharedstate"
#    key            = "global/s3/terraform.tfstate"
#    region         = "ca-central-1"
#    dynamodb_table = "shsca5-tflocks"
#    encrypt        = true
#  }
#}

# Infrastructure
provider "aws" {
	region = "${var.aws_region}"
	
	#uncomment if you set these variables in vars.tf
	#Comment out if you wish to use ENV variables for auth tokens
	#access_key = var.SP.access_key
	#secret_key = var.SP.secret_key
}

# Setup Onboarding scripts
data "template_file" "vm_onboard" {
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
  }
}

locals {
    depends_on   = []
    az1_mgmt_gw  = "${cidrhost(var.az1_security_subnets.mgmt, 1)}"
    az2_mgmt_gw  = "${cidrhost(var.az2_security_subnets.mgmt, 1)}"
    az1_paz_gw   = "${cidrhost(var.az1_security_subnets.paz_ext, 1)}"
    az2_paz_gw   = "${cidrhost(var.az2_security_subnets.paz_ext, 1)}"
}

# Render Onboarding script
resource "local_file" "vm_onboarding_file" {
  content     = "${data.template_file.vm_onboard.rendered}"
  filename    = "${path.module}/${var.onboard_script}"
}






output "Hub_Transit_Gateway_ID" { value = "${aws_ec2_transit_gateway.hubtgw.id}" }

output "MAZ_Portal_Local_VIP" { value = "NULL" }
output "MAZ_Portal_EIP" { value = "NULL" }

output "Tenant-1_Workload_Local_VIP" { value = "NULL" }
output "Tenant-1_Workload_EIP" { value = "NULL" }