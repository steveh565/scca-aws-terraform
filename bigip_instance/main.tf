// provider, backend, storage and networking/vpc should be moved/handled in the root main/init calling module //
provider "aws" {
  region  = var.aws_region
  profile = "default"
  // access_key and secret_key values should come from environment variables, don't store in here to keep them safe //
}

/*
// set the backend to store the terraform state file in S3, for collaboration  //
terraform {
  backend "s3" {
    bucket = "terraform_state"
    key    = "terraform/terraform.tfstate"
    region = "ca-central-1"
  }
}
*/

// for CF, AWS IAM role with specific privileges must be assigned to each bigip EC2 instance //
// In AWS, go to IAM > Roles and create a policy with the following permissions:
//    - EC2 Read/Write
//    - S3 Read/Write
//    - STS Assume Role

resource "aws_iam_role" "bigip-Failover-Extension-IAM-role" {
  name = "bigip-Failover-Extension-IAM-role"

  assume_role_policy = file("${path.module}/bigip-Failover-Extension-IAM-role-Assume-Role.json")

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_policy" "bigip-Failover-Extension-IAM-policy" {
  name        = "bigip-Failover-Extension-IAM-policy"
  description = "for bigip cloud failover extension"
  policy      = file("bigip-Failover-Extension-IAM-policy.json")
}

resource "aws_iam_policy_attachment" "bigip-Failover-Extension-IAM-policy-attach" {
  name       = "bigip-Failover-Extension-IAM-policy-attach"
  roles      = [aws_iam_role.bigip-Failover-Extension-IAM-role.name]
  policy_arn = aws_iam_policy.bigip-Failover-Extension-IAM-policy.arn
}


resource "aws_iam_instance_profile" "bigip-Failover-Extension-IAM-instance-profile" {
  name = "bigip-Failover-Extension-IAM-instance-profile"
  role = aws_iam_role.bigip-Failover-Extension-IAM-role.name
}

/*
// INPUT VARIABLES FOR DAN's TEMPORARY TESTING: //
*/
variable subnet_mgmt_id { default = "subnet-0a094afdb3da643e7" }
variable aws_security_group {
  type = map
  default = {
    sg_ext_mgmt = "sg-0d240145dbf1a93a9"
    sg_external = "sg-0d240145dbf1a93a9"
    sg_internal = "sg-0d240145dbf1a93a9"
  }
}
variable subnet_ext_id { default = "subnet-0471ee7772cc91d63" }
variable bigip_ext_sg { default = "sg-0d240145dbf1a93a9" }
variable subnet_int_id { default = "subnet-05506b7d2258805fd" }
variable bigip_int_sg { default = "sg-0d240145dbf1a93a9" }
variable key_name { default = "terraform-daniel-keypair" }
variable public_key_path { default = "/Users/cayer/.ssh/id_rsa_aws_daniel.pub" }
variable domain_name { default = "example.com" }
variable advisory_text { default = "/Common/hostname" }
variable advisory_color { default = "green" }

// Deploy BIGIP //

// Create and attach bigip tmm network interfaces           //

resource "aws_network_interface" "mgmt" {
  subnet_id       = var.subnet_mgmt_id
  private_ips     = [var.az1_ztsra_transitF5.mgmt]
  security_groups = [var.aws_security_group.sg_ext_mgmt]
  security_groups = [var.bigip_mgmt_sg]
}

resource "aws_network_interface" "external" {
  subnet_id       = var.subnet_ext_id
  private_ips     = [var.az1_ztsra_transitF5.transit_self]
  security_groups = [var.aws_security_group.sg_external]
}

resource "null_resource" "external_secondary_ips" {
  depends_on = [aws_network_interface.external]
  # Use the "aws ec2 assign-private-ip-addresses" command to add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --network-interface-id ${aws_network_interface.external.id} --private-ip-addresses ${var.az1_ztsra_transitF5.transit_vip}
    EOF
  }
}

resource "aws_network_interface" "internal" {
  subnet_id       = var.subnet_int_id
  private_ips     = [var.az1_ztsra_transitF5.internal_self]
  security_groups = [var.aws_security_group.sg_internal]
}

resource "null_resource" "internal_secondary_ips" {
  depends_on = [aws_network_interface.internal]
  # Use the "aws ec2 assign-private-ip-addresses" command to add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --network-interface-id ${aws_network_interface.internal.id} --private-ip-addresses ${var.az1_ztsra_transitF5.internal_vip}
    EOF
  }
}

# Create and map elastic IPs external and mgmt nics
resource "aws_eip" "eip_az1_mgmt" {
  depends_on                = [aws_network_interface.az1_mgmt]
  vpc                       = true
  network_interface         = aws_network_interface.external.id
  associate_with_private_ip = var.az1_ztsra_transitF5.mgmt
}

resource "aws_eip" "eip_az1_vip" {
  vpc                       = true
  network_interface         = aws_network_interface.external.id
  associate_with_private_ip = var.az1_ztsra_transitF5.transit_vip
}

resource "aws_eip" "eip_az1_ext_self" {
  vpc                       = true
  network_interface         = aws_network_interface.external.id
  associate_with_private_ip = var.az1_ztsra_transitF5.transit_self
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
resource "aws_instance" "ztsra_bigip_az1" {
  ami           = var.ami_f5image_name
  instance_type = var.ami_ztsra_f5iinstance_type
  #  associate_public_ip_address = false
  availability_zone      = var.aws_region}a
  user_data              = data.template_file.ve_onboard.rendered
  #  key_name      = "kp${var.tag_name}"
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.bigip-Failover-Extension-IAM-instance-profile.name
  root_block_device {
    delete_on_termination = true
  }

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.az1_mgmt.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.az1_external.id
  }
  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.az1_internal.id
  }

  provisioner "remote-exec" {
/*
    connection {
      host     = "${aws_instance.ztsra_bigip_az1.public_ip}"
      type     = "ssh"
      user     = "${var.uname}"
      password = "${var.upassword}"
    }
    when = "create"
    inline = [
      "until [ -f ${var.onboard_log} ]; do sleep 120; done; sleep 120"
    ]
  }
*/

  provisioner "remote-exec" {
    connection {
      host     = "${aws_instance.az1_bigip.public_ip}"
      type     = "ssh"
      user     = "${var.uname}"
      password = "${var.upassword}"
    }
    when = destroy
    inline = [
      "echo y | tmsh revoke sys license"
    ]
    on_failure = continue
  }

  tags = {
    Name = "${var.tag_name}-${var.az1_ztsra_transitF5.hostname}"
  }
}

# setup bigip declarative onboarding (DO) script for licensing and initial/base configuration
data "template_file" "bigip_do_json" {
  template = "${file("${path.module}/cluster.json")}"

  vars = {
    #Uncomment the following line for BYOL
    regkey                 = "${var.ztsra_bigip_lic1}"
    host1                  = "${var.az1_ztsra_transitF5.hostname}"
    host2                  = "${var.az2_ztsra_transitF5.hostname}"
    local_host             = "${var.az1_ztsra_transitF5.hostname}"
    admin_user             = var.uname
    localPassword          = var.upassword
    admin_password         = var.upassword
    remote_selfip          = var.az2_ztsra_transitF5.mgmt
    domain_name            = var.domain_name
    advisory_color         = var.advisory_color
    advisory_text          = var.advisory_text
    provision_ltm          = var.provision_ltm
    provision_avr          = var.provision_avr
    provision_ilx          = var.provision_ilx
    provision_asm          = var.provision_asm
    provision_apm          = var.provision_apm
    bigip_ext_priv_self_ip = var.az1_ztsra_transitF5.transit_self
    bigip_int_priv_self_ip = var.az1_ztsra_transitF5.internal_self
    gateway                = cidrhost(var.az1_ztsra_subnets.transit, 1)
    #    gateway                = cidrhost(var.maz_ext1_cidr, 1)
    dns_server  = "${var.dns_server}"
    ntp_server  = "${var.ntp_server}"
    timezone    = "${var.timezone}"
    app1_net    = var.tenant_vpc_cidr
    app1_net_gw = cidrhost(var.az1_ztsra_subnets.transit, 1)
  }
}

# save bigip DO to local file
resource "local_file" "bigip_do_file" {
  content  = data.template_file.bigip_do_json.rendered
  filename = "${path.module}/${var.az1_maz_do_json}"
}

# push DO declaration onto bigip
resource "null_resource" "bigip_DO" {
  depends_on = [aws_instance.bigip]
  # Running DO REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_do_method} https://${aws_instance.bigip.public_ip}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.az1_maz_do_json}
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
#  depends_on = [null_resource.bigip_DO]
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
#output "mgmt_subnet_gw" { value = cidrhost(var.maz_mgmt1_cidr, 1) }
#output "ext_subnet_gw" { value = cidrhost(var.maz_ext1_cidr, 1) }
#output "ALB_app1_pip" { value = "${data.azurerm_public_ip.lbpip.ip_address}" }

#output "f5vm01_id" { value = "${azurerm_virtual_machine.f5vm01.id}" }
#output "f5vm01_mgmt_private_ip" { value = "${azurerm_network_interface.f5vm01-mgmt-nic.private_ip_address}" }
output "f5vm01_mgmt_public_ip" { value = "${aws_instance.bigip.public_ip}" }
#output "f5vm01_ext_private_ip" { value = "${azurerm_network_interface.f5vm01-ext-nic.private_ip_address}" }
