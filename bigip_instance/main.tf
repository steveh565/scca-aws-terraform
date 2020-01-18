/*
// provider, backend, storage and networking/vpc are handled in main/init module //
provider "aws" {
  region  = var.aws_region
  profile = "default"
  #  access_key = var.access_key
  #  secret_key = var.secret_key
}

terraform {
  backend "s3" {
    bucket = "dc-f5-terraforom-aws"
    key    = "terraform/terraform.tfstate"
    #can't reference variables here, because this occurs before the variables are set?
    region = "ca-central-1"
  }
}

# Deploy Storage Resource
module "storage" {
  source       = "./storage"
  project_name = var.project_name
}

# Deploy Networking Resources

module "networking" {
  source            = "./networking"
  vpc_cidr          = var.vpc_cidr
  project_name      = var.project_name
  mgmt_cidr         = var.mgmt_cidr
  ext_cidr          = var.ext_cidr
  int_cidr          = var.int_cidr
  tosc_cidr         = var.subnets.subnet3
  frsc_cidr         = var.subnets.subnet4
  availability_zone = var.availability_zone
}
*/

/*
// INPUT VARIABLES: //
*/

variable subnet_mgmt_id {}
variable bigip_mgmt_priv_ip {}
variable bigip_mgmt_sg {}
variable subnet_ext_id {}
variable bigip_ext_priv_self_ip {}
variable bigip_ext_priv_vip1 {}
variable bigip_ext_sg {}
variable ext_gw {}
variable subnet_int_id {}
variable bigip_int_priv_self_ip {}
variable bigip_int_priv_vip1 {}
variable bigip_int_sg {}
variable app1_net {}
variable app1_net_gw {}
variable rest_bigip_do_file { default = "bigip_do_data.json" } # path/filename to save DO declaration
variable key_name {}
variable public_key_path {}
variable uname {}
variable upassword {}
variable DO_onboard_URL {}
variable AS3_URL {}
variable TS_URL {}
variable CF_URL {}
variable libs_dir {}
variable onboard_log {}
variable instance_type {}
variable associate_public_ip_address { default = true }
variable availability_zone {}
variable tag_name { default = "cfSHSCA5" }
variable ve_name { default = "bigip" }
variable license {}
variable domain_name { default = "example.com" }
variable host1_name {}
variable host2_name {}
variable advisory_text { default = "/Common/hostname" }
variable advisory_color {}
variable dns_server {}
variable ntp_server {}
variable timezone {}
variable provision_ltm { default = "nominal" }
variable provision_avr { default = "nominal" }
variable provision_ilx { default = "nominal" }
variable provision_asm { default = "nominal" }
variable provision_apm { default = "nominal" }


// Deploy BIGIP //

// Create and attach bigip tmm network interfaces           //
// (mgmt interface is handled by aws_instance module below) //
resource "aws_network_interface" "external" {
  depends_on      = ["aws_instance.bigip"]
  subnet_id       = var.subnet_ext_id
  private_ips     = [var.bigip_ext_priv_self_ip, var.bigip_ext_priv_vip1]
  security_groups = [var.bigip_ext_sg]
  attachment {
    instance     = aws_instance.bigip.id
    device_index = 1
  }
}

resource "aws_network_interface" "internal" {
  depends_on      = ["aws_instance.bigip"]
  subnet_id       = var.subnet_int_id
  private_ips     = [var.bigip_int_priv_self_ip, var.bigip_int_priv_vip1]
  security_groups = [var.bigip_int_sg]
  attachment {
    instance     = aws_instance.bigip.id
    device_index = 2
  }
}

/*
// uncomment and adjust for additional interfaces... and don't forget to adjust cluster.json do template accordingly! //
resource "aws_network_interface" "ToSC" {
  depends_on      = ["aws_instance.bigip"]
  subnet_id       = module.networking.tosc_subnet_id
  private_ips     = [var.f5vm01ToSC, var.f5vm01ToSC_sec]
  security_groups = [module.networking.sg_allow_all]
  attachment {
    instance     = aws_instance.bigip.id
    device_index = 3
  }
}

resource "aws_network_interface" "FrSC" {
  depends_on      = ["aws_instance.bigip"]
  subnet_id       = module.networking.frsc_subnet_id
  private_ips     = [var.f5vm01FrSC, var.f5vm01FrSC_sec]
  security_groups = [module.networking.sg_allow_all]
  attachment {
    instance     = aws_instance.bigip.id
    device_index = 4
  }
}
*/

// Create and associate public IP to bigip_ext_priv_vip1    //
// (mgmt interface is handled by aws_instance module below) //
resource "aws_eip" "eip_vip" {
  vpc                       = true
  network_interface         = aws_network_interface.external.id
  associate_with_private_ip = var.bigip_ext_priv_vip1
}

// Create a new key pair for login access to this bigip instance                          //
// alternatiely, this new key pair could be done in main module, and used for all bigip's //
resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}


# Setup initial Onboarding script
data "template_file" "ve_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname          = "${var.uname}"
    upassword      = "${var.upassword}"
    DO_onboard_URL = "${var.DO_onboard_URL}"
    AS3_URL        = "${var.AS3_URL}"
    TS_URL         = "${var.TS_URL}"
    CF_URL         = "${var.CF_URL}"
    libs_dir       = "${var.libs_dir}"
    onboard_log    = "${var.onboard_log}"
  }
}

# deploy bigip EC2 VM instance, with execution of initial onboarding script
resource "aws_instance" "bigip" {
  ami                         = "ami-038e6394d715e5eac"
  instance_type               = var.instance_type
  associate_public_ip_address = true
  private_ip                  = var.bigip_mgmt_priv_ip
  availability_zone           = var.availability_zone
  subnet_id                   = var.subnet_mgmt_id
  security_groups             = [var.bigip_mgmt_sg]
  vpc_security_group_ids      = [var.bigip_mgmt_sg]
  user_data                   = data.template_file.ve_onboard.rendered
  key_name                    = var.key_name
  root_block_device {
    delete_on_termination = true
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "tmsh revoke /sys license"
    ]
    on_failure = "continue"
  }

  tags = {
    Name = "${var.tag_name}-${var.ve_name}"
  }
}

# setup bigip declarative onboarding (DO) script for licensing and initial/base configuration
data "template_file" "bigip_do_json" {
  template = "${file("${path.module}/cluster.json")}"

  vars = {
    #Uncomment the following line for BYOL
    regkey = "${var.license}"

    host1                  = "${var.host1_name}"
    host2                  = "${var.host2_name}"
    local_host             = "${var.host1_name}"
    provision_ltm          = var.provision_ltm
    provision_avr          = var.provision_avr
    provision_ilx          = var.provision_ilx
    provision_asm          = var.provision_asm
    provision_ltm          = var.provision_ltm
    bigip_ext_priv_self_ip = var.bigip_ext_priv_self_ip
    bigip_int_priv_self_ip = var.bigip_int_priv_self_ip
    gateway                = "${local.ext_gw}"
    dns_server             = "${var.dns_server}"
    ntp_server             = "${var.ntp_server}"
    timezone               = "${var.timezone}"
    app1_net               = "${local.app1_net}"
    app1_net_gw            = "${local.app1_net_gw}"
  }
}

# save bigip DO to local file
resource "local_file" "f5vm01_do_file" {
  content  = data.template_file.bigip_do_json.rendered
  filename = "${path.module}/${var.rest_bigip_do_file}"
}

# push DO declaration onto bigip
resource "null_resource" "f5vm01_DO" {
  depends_on = ["aws_instance.bigip"]
  # Running DO REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_do_method} https://${aws_instance.bigip.public_ip}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_bigip_do_file}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${aws_instance.bigip.public_ip}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 120
    EOF
  }
}

// add code for cloud failover declaration here //


#data "template_file" "ts_json" {
#  template   = "${file("${path.module}/ts.json")}"
#  depends_on = ["azurerm_log_analytics_workspace.law"]
#  vars = {
#    location    = "${var.location}"
#    law_id      = "${azurerm_log_analytics_workspace.law.workspace_id}"
#    law_primkey = "${azurerm_log_analytics_workspace.law.primary_shared_key}"
#  }
#}

#resource "local_file" "vm_ts_file" {
#  content  = data.template_file.ts_json.rendered
#  filename = "${path.module}/${var.rest_vm_ts_file}"
#}

#resource "null_resource" "f5vm01_TS" {
#  depends_on = [null_resource.f5vm01_DO]
#  # Running CF REST API
#  provisioner "local-exec" {
#    command = <<-EOF
#      #!/bin/bash
#      curl -H 'Content-Type: application/json' -k -X POST https://${aws_instance.bigip.public_ip}${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_ts_file}
#    EOF
#  }
#}


## OUTPUTS ###
#data "azurerm_public_ip" "f5vm01mgmtpip" {
#  name                = "${azurerm_public_ip.f5vm01mgmtpip.name}"
#  resource_group_name = "${azurerm_resource_group.main.name}"
#  depends_on          = [azurerm_virtual_machine.f5vm01]
#}
#data "azurerm_public_ip" "lbpip" {
#  name                = "${azurerm_public_ip.extlbpip.name}"
#  resource_group_name = "${azurerm_resource_group.main.name}"
#  depends_on          = [azurerm_virtual_machine.f5vm02]
#}

#output "sg_id" { value = "${azurerm_network_security_group.main.id}" }
#output "sg_name" { value = "${azurerm_network_security_group.main.name}" }
output "mgmt_subnet_gw" { value = "${local.mgmt_gw}" }
output "ext_subnet_gw" { value = "${local.ext_gw}" }
#output "ALB_app1_pip" { value = "${data.azurerm_public_ip.lbpip.ip_address}" }

#output "f5vm01_id" { value = "${azurerm_virtual_machine.f5vm01.id}" }
#output "f5vm01_mgmt_private_ip" { value = "${azurerm_network_interface.f5vm01-mgmt-nic.private_ip_address}" }
output "f5vm01_mgmt_public_ip" { value = "${aws_instance.bigip.public_ip}" }
#output "f5vm01_ext_private_ip" { value = "${azurerm_network_interface.f5vm01-ext-nic.private_ip_address}" }
