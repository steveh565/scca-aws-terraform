# Create and attach bigip tmm network interfaces
resource "aws_network_interface" "az1_maz_mgmt" {
  depends_on      = [aws_security_group.maz_sg_ext_mgmt]
  subnet_id       = aws_subnet.az1_maz_mgmt.id
  private_ips     = [var.tenant_values.maz.az1.mgmt]
  security_groups = [aws_security_group.maz_sg_ext_mgmt.id]
}

resource "aws_network_interface" "az1_maz_external" {
  depends_on      = [aws_security_group.maz_sg_internal]
  subnet_id       = aws_subnet.az1_maz_ext.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [var.tenant_values.maz.az1.ext_self]
  security_groups = [aws_security_group.maz_sg_internal.id]
  source_dest_check = false
  tags              = {
    "f5_cloud_failover_label" = var.maz_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "null_resource" "az1_maz_external_secondary_ips" {
  depends_on = [aws_network_interface.az1_maz_external, aws_instance.az1_maz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az1_maz_external.id} --private-ip-addresses ${var.tenant_values.maz.az1.ext_vip}
    EOF
  }
}

resource "aws_network_interface" "az1_maz_internal" {
  depends_on      = [aws_security_group.maz_sg_internal]
  subnet_id       = aws_subnet.az1_maz_int.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [var.tenant_values.maz.az1.int_self]
  security_groups = [aws_security_group.maz_sg_internal.id]
  source_dest_check = false
  tags              = {
    "f5_cloud_failover_label" = var.tenant_values.maz.cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "null_resource" "az1_maz_internal_secondary_ips" {
  depends_on = [aws_network_interface.az1_maz_internal, aws_instance.az1_maz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az1_maz_internal.id} --private-ip-addresses ${var.tenant_values.maz.az1.int_vip}
    EOF
  }
}

# Create elastic IP and map to "VIP" on external maz nic
resource "aws_eip" "eip_az1_maz_mgmt" {
  depends_on                = [aws_network_interface.az1_maz_mgmt]
  vpc                       = true
  network_interface         = aws_network_interface.az1_maz_mgmt.id
  associate_with_private_ip = var.tenant_values.maz.az1.mgmt
}

resource "aws_eip" "eip_az1_maz_external" {
  depends_on                = [aws_network_interface.az1_maz_external]
  vpc                       = true
  network_interface         = aws_network_interface.az1_maz_external.id
  associate_with_private_ip = var.tenant_values.maz.az1.ext_self
}

#Big-IP 1
resource "aws_instance" "az1_maz_bigip" {
  depends_on    = [aws_eip.eip_az1_maz_mgmt, aws_subnet.az1_maz_mgmt, aws_security_group.maz_sg_ext_mgmt, aws_network_interface.az1_maz_mgmt, aws_network_interface.az1_maz_internal, aws_network_interface.az1_maz_external]
  ami           = var.ami_f5image_name
  instance_type = var.ami_maz_f5instance_type
  availability_zone           = "${var.aws_region}a"
  user_data     = data.template_file.az1_mazF5_vm_onboard.rendered
  iam_instance_profile        = var.iam_instance_profile
  key_name      = "kp${var.tag_name}"
  root_block_device {
    delete_on_termination = true
  }
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.az1_maz_mgmt.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.az1_maz_external.id
  }
  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.az1_maz_internal.id
  }
  provisioner "remote-exec" {
    connection {
      host     = self.public_ip
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "until [ -f ${var.onboard_log} ]; do sleep 120; done; sleep 120"
    ]
  }
  tags = {
    Name = "${var.tag_name}-${var.tenant_values.maz.az1.hostname}"
  }
}

# Recycle/revoke eval keys (useful for demo purposes)
resource "null_resource" "revoke_eval_keys_upon_destroy_maz1" {
  depends_on = [
    aws_route_table_association.az1_maz_ext,
    aws_route_table_association.az1_maz_mgmt,
#    aws_iam_policy_attachment.bigip-failover-extension-iam-policy-attach,
#    aws_iam_policy.bigip-failover-extension-iam-policy,
    aws_security_group.maz_sg_external,
#    aws_key_pair.main,
    aws_route_table.maz_MgmtRt,
    # aws_ec2_transit_gateway_route_table.hubtgwRt,
    aws_ec2_transit_gateway_vpc_attachment.mazTgwAttach,
    aws_ec2_transit_gateway.hubtgw,
    aws_instance.az1_maz_bigip,
    aws_eip.eip_az1_maz_external,
    aws_eip.eip_az1_maz_mgmt,
    aws_internet_gateway.mazGw
  ]
  for_each = {
    bigipmaz1 = aws_instance.az1_maz_bigip.public_ip
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



# Create and attach bigip tmm network interfaces
resource "aws_network_interface" "az2_maz_mgmt" {
  depends_on      = [aws_security_group.maz_sg_ext_mgmt]
  subnet_id       = aws_subnet.az2_maz_mgmt.id
  private_ips     = [var.az2_mazF5.mgmt]
  security_groups = [aws_security_group.maz_sg_ext_mgmt.id]
}

resource "aws_network_interface" "az2_maz_external" {
  depends_on      = [aws_security_group.maz_sg_internal]
  subnet_id       = aws_subnet.az2_maz_ext.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [var.az2_mazF5.maz_ext_self]
  security_groups = [aws_security_group.maz_sg_internal.id]
  source_dest_check = false
  tags              = {
    f5_cloud_failover_label = var.maz_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "null_resource" "az2_maz_external_secondary_ips" {
  depends_on = [aws_network_interface.az2_maz_external, aws_instance.az2_maz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az2_maz_external.id} --private-ip-addresses ${var.az2_mazF5.maz_ext_vip}
    EOF
  }
}

resource "aws_network_interface" "az2_maz_internal" {
  depends_on      = [aws_security_group.maz_sg_internal]
  subnet_id       = aws_subnet.az2_maz_int.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [var.az2_mazF5.maz_int_self]
  security_groups = [aws_security_group.maz_sg_internal.id]
  source_dest_check = false
  tags              = {
    f5_cloud_failover_label = var.maz_cf_label
  }  
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "null_resource" "az2_maz_internal_secondary_ips" {
  depends_on = [aws_network_interface.az2_maz_internal, aws_instance.az2_maz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az2_maz_internal.id} --private-ip-addresses ${var.az2_mazF5.maz_int_vip}
    EOF
  }
}

resource "aws_eip" "eip_az2_maz_mgmt" {
  depends_on                = [aws_network_interface.az2_maz_mgmt]
  vpc                       = true
  network_interface         = aws_network_interface.az2_maz_mgmt.id
  associate_with_private_ip = var.az2_mazF5.mgmt
}

resource "aws_eip" "eip_az2_maz_external" {
  depends_on                = [aws_network_interface.az2_maz_external]
  vpc                       = true
  network_interface         = aws_network_interface.az2_maz_external.id
  associate_with_private_ip = var.az2_mazF5.maz_ext_self
}


# BigIP 2
resource "aws_instance" "az2_maz_bigip" {
  depends_on        = [aws_eip.eip_az2_maz_mgmt, aws_subnet.az2_maz_mgmt, aws_security_group.maz_sg_ext_mgmt, aws_network_interface.az2_maz_external, aws_network_interface.az2_maz_internal, aws_network_interface.az2_maz_mgmt]
  ami               = var.ami_f5image_name
  instance_type     = var.ami_maz_f5instance_type
  availability_zone = "${var.aws_region}b"
  user_data         = data.template_file.az2_mazF5_vm_onboard.rendered
#  iam_instance_profile        = aws_iam_instance_profile.bigip-failover-extension-iam-instance-profile.name
  iam_instance_profile        = var.iam_instance_profile
  key_name          = "kp${var.tag_name}"
  root_block_device {
    delete_on_termination = true
  }
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.az2_maz_mgmt.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.az2_maz_external.id
  }
  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.az2_maz_internal.id
  }
  provisioner "remote-exec" {
    connection {
      host     = self.public_ip
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "until [ -f ${var.onboard_log} ]; do sleep 120; done; sleep 120"
    ]
  }

  tags = {
    Name = "${var.tag_name}-${var.az2_mazF5.hostname}"
  }
}

# Recycle/revoke eval keys (useful for demo purposes)
resource "null_resource" "revoke_eval_keys_upon_destroy_maz2" {
  depends_on = [
    aws_route_table_association.az2_maz_ext,
    aws_route_table_association.az2_maz_mgmt,
#    aws_iam_policy_attachment.bigip-failover-extension-iam-policy-attach,
#    aws_iam_policy.bigip-failover-extension-iam-policy,
    aws_security_group.maz_sg_external,
#    aws_key_pair.main,
    aws_route_table.maz_intRt,
    aws_route_table.maz_MgmtRt,
    aws_ec2_transit_gateway_vpc_attachment.mazTgwAttach,
    aws_ec2_transit_gateway.hubtgw,
    aws_instance.az2_maz_bigip,
    aws_eip.eip_az2_maz_external,
    aws_internet_gateway.mazGw,
    aws_eip.eip_az2_maz_mgmt
  ]
  for_each = {
    bigipmaz2 = aws_instance.az2_maz_bigip.public_ip
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



## AZ1 DO Declaration
data "template_file" "az1_mazCluster_do_json" {
  template = "${file("${path.module}/maz_clusterAcrossAZs_do.tpl.json")}"
  vars = {
    #Uncomment the following line for BYOL
    regkey         = var.tenant_values.maz.az1.bigip_lic
    banner_color   = "red"
    Domainname     = var.f5Domainname
    host1          = var.tenant_values.maz.az1.hostname
    host2          = var.tenant_values.maz.az2.hostname
    local_host     = var.tenant_values.maz.az1.hostname
    local_selfip1  = var.tenant_values.maz.az1.ext_self
    local_selfip2  = var.tenant_values.maz.az1.int_self
    #remote_selfip must be set to the same value on both bigips in order for HA clustering to work
    remote_selfip  = var.tenant_values.maz.az1.mgmt
    mgmt_gw        = local.az1_mgmt_gw
    gateway        = local.az1_maz_ext_gw
    dns_server     = var.dns_server
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
  }
}

# Render maz DO declaration
resource "local_file" "az1_mazCluster_do_file" {
  content  = data.template_file.az1_mazCluster_do_json.rendered
  filename = "${path.module}/${var.az1_mazCluster_do_json}"
}

## AZ2 DO Declaration
data "template_file" "az2_mazCluster_do_json" {
  template = "${file("${path.module}/maz_clusterAcrossAZs_do.tpl.json")}"
  vars = {
    #Uncomment the following line for BYOL
    regkey         = var.tenant_values.maz.az2.bigip_lic
    banner_color   = "red"
    Domainname     = var.f5Domainname
    host1          = var.tenant_values.maz.az1.hostname
    host2          = var.tenant_values.maz.az2.hostname
    local_host     = var.tenant_values.maz.az2.hostname
    local_selfip1  = var.tenant_values.maz.az2.ext_self
    local_selfip2  = var.tenant_values.maz.az2.int_self
    #remote_selfip must be set to the same value on both bigips in order for HA clustering to work
    remote_selfip  = var.tenant_values.maz.az1.mgmt
    mgmt_gw        = local.az2_mgmt_gw
    gateway        = local.az2_maz_ext_gw
    dns_server     = var.dns_server
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
  }
}

# Render maz DO declaration
resource "local_file" "az2_maz_do_file" {
  content  = data.template_file.az2_mazCluster_do_json.rendered
  filename = "${path.module}/${var.az2_mazCluster_do_json}"
}

# MAZ CF Declaration
data "template_file" "maz_cf_json" {
  template = "${file("${path.module}/maz_cloudfailover.tpl.json")}"

  vars = {
    cf_label = var.maz_cf_label
    cf_cidr1 = "100.100.1.0/24"
    cf_cidr2 = var.maz_aip_cidr
    cf_nexthop1 = var.tenant_values.maz.az1.ext_self
    cf_nexthop2 = var.tenant_values.maz.az2.ext_self
  }
}

# Render MAZ CF Declaration
resource "local_file" "maz_cf_file" {
  content  = data.template_file.maz_cf_json.rendered
  filename = "${path.module}/${var.maz_cf_json}"
}

# MAZ TS Declaration
data "template_file" "maz_ts_json" {
  template = "${file("${path.module}/tsCloudwatch_ts.tpl.json")}"

  vars = {
    aws_region = var.aws_region
  }
}

# Render maz TS declaration
resource "local_file" "maz_ts_file" {
  content  = data.template_file.maz_ts_json.rendered
  filename = "${path.module}/${var.maz_ts_json}"
}

# maz LogCollection AS3 Declaration
data "template_file" "maz_logs_as3_json" {
  template = "${file("${path.module}/tsLogCollection_as3.tpl.json")}"

  vars = {

  }
}

# Render maz LogCollection AS3 declaration
resource "local_file" "maz_logs_as3_file" {
  content  = data.template_file.maz_logs_as3_json.rendered
  filename = "${path.module}/${var.maz_logs_as3_json}"
}

/*
# MAZ AS3 Declaration
data "template_file" "maz_as3_json" {
  template = file("${path.module}/maz_as3.tpl.json")

  vars = {
    backendvm_ip   = aws_instance.bastionHost[0].private_ip
    asm_policy_url = var.asm_policy_url
  }
}

# Render maz AS3 declaration
resource "local_file" "maz_as3_file" {
  content  = data.template_file.maz_as3_json.rendered
  filename = "${path.module}/${var.maz_as3_json}"
}
*/

# Send declarations via REST API's
resource "null_resource" "az1_mazF5_DO" {
  depends_on = [aws_instance.az1_maz_bigip]
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -s -X ${var.rest_do_method} https://${aws_instance.az1_maz_bigip.public_ip}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${path.module}/${var.az1_mazCluster_do_json}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${aws_instance.az1_maz_bigip.public_ip}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 120
    EOF
  }
}

resource "null_resource" "az2_mazF5_DO" {
  depends_on = [aws_instance.az2_maz_bigip]
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -s -X ${var.rest_do_method} https://${aws_instance.az2_maz_bigip.public_ip}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${path.module}/${var.az2_mazCluster_do_json}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${aws_instance.az2_maz_bigip.public_ip}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 120
    EOF
  }
}

resource "null_resource" "mazF5_CF" {
  depends_on	= [null_resource.az1_mazF5_DO, null_resource.az2_mazF5_DO, module.storage-maz.bucketname]
  for_each = {
    bigip1 = aws_instance.az1_maz_bigip.public_ip
    bigip2 = aws_instance.az2_maz_bigip.public_ip
  }
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -s -X ${var.rest_do_method} https://${each.value}${var.rest_cf_uri} -u ${var.uname}:${var.upassword} -d @${path.module}/${var.maz_cf_json}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${each.value}/mgmt/shared/cloud-failover/declare -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "success" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 30
    EOF
  }
}

resource "null_resource" "mazF5_TS" {
  depends_on = [null_resource.mazF5_CF]
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -H 'Content-Type: application/json' -k -X POST https://${aws_instance.az1_maz_bigip.public_ip}${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @${path.module}/${var.maz_ts_json}
    EOF
  }
}

resource "null_resource" "mazF5_TS_LogCollection" {
  depends_on = [null_resource.mazF5_TS]
  # Running CF REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -H 'Content-Type: application/json' -k -X POST https://${aws_instance.az1_maz_bigip.public_ip}${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @${path.module}/${var.maz_logs_as3_json}
    EOF
  }
}
