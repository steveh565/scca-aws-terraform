# Create and attach bigip tmm network interfaces
resource "aws_network_interface" "az1_dmz_mgmt" {
  depends_on      = [aws_security_group.sg_ext_mgmt]
  subnet_id       = aws_subnet.az1_mgmt.id
  private_ips     = [var.az1_dmzF5.mgmt]
  security_groups = [aws_security_group.sg_ext_mgmt.id]
}

resource "aws_network_interface" "az1_dmz_external" {
  depends_on      = [aws_security_group.sg_external]
  subnet_id       = aws_subnet.az1_dmzExt.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [var.az1_dmzF5.dmz_ext_self]
  security_groups = [aws_security_group.sg_external.id]
  source_dest_check = false
  tags = {
    f5_cloud_failover_label = var.dmz_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "null_resource" "az1_dmz_external_secondary_ips" {
  depends_on = [aws_network_interface.az1_dmz_external, aws_instance.az1_dmz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az1_dmz_external.id} --private-ip-addresses ${var.az1_dmzF5.dmz_ext_vip}
    EOF
  }
}

resource "aws_network_interface" "az1_dmz_internal" {
  depends_on      = [aws_security_group.sg_internal]
  subnet_id       = aws_subnet.az1_dmzInt.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [var.az1_dmzF5.dmz_int_self]
  security_groups = [aws_security_group.sg_internal.id]
  source_dest_check = false
  tags = {
    f5_cloud_failover_label = var.dmz_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "null_resource" "az1_dmz_internal_secondary_ips" {
  depends_on = [aws_network_interface.az1_dmz_internal, aws_instance.az1_dmz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az1_dmz_internal.id} --private-ip-addresses ${var.az1_dmzF5.dmz_int_vip}
    EOF
  }
}

# Create elastic IP and map to "VIP" on external dmz nic
resource "aws_eip" "eip_az1_dmz_mgmt" {
  depends_on                = [aws_network_interface.az1_dmz_mgmt, aws_internet_gateway.gw]
  vpc                       = true
  network_interface         = aws_network_interface.az1_dmz_mgmt.id
  associate_with_private_ip = var.az1_dmzF5.mgmt
}

resource "aws_eip" "eip_az1_dmz_external" {
  depends_on                = [aws_network_interface.az1_dmz_external, aws_internet_gateway.gw]
  vpc                       = true
  network_interface         = aws_network_interface.az1_dmz_external.id
  associate_with_private_ip = var.az1_dmzF5.dmz_ext_self
}

#Big-IP 1
resource "aws_instance" "az1_dmz_bigip" {
  depends_on    = [aws_eip.eip_az1_dmz_mgmt, aws_subnet.az1_mgmt, aws_security_group.sg_ext_mgmt, aws_network_interface.az1_dmz_external, aws_network_interface.az1_dmz_internal, aws_network_interface.az1_dmz_mgmt]
  ami           = var.ami_f5image_name
  instance_type = var.ami_dmz_f5instance_type
  availability_zone           = "${var.aws_region}a"
  user_data     = data.template_file.az1_dmzF5_vm_onboard.rendered
  iam_instance_profile        = aws_iam_instance_profile.bigip-failover-extension-iam-instance-profile.name
  key_name      = "kp${var.tag_name}"
  root_block_device {
    delete_on_termination = true
  }
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.az1_dmz_mgmt.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.az1_dmz_external.id
  }
  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.az1_dmz_internal.id
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
    Name = "${var.tag_name}-${var.az1_dmzF5.hostname}"
  }
}

# Recycle/revoke eval keys (useful for demo purposes)
resource "null_resource" "revoke_eval_keys_upon_destroy_dmz1" {
  depends_on = [
    aws_internet_gateway.gw,
    aws_iam_policy_attachment.bigip-failover-extension-iam-policy-attach,
    aws_iam_policy.bigip-failover-extension-iam-policy,
    aws_key_pair.main,
    aws_security_group.sg_external,
    aws_route_table.DmzExtRt,
    aws_ec2_transit_gateway_vpc_attachment.hubTgwAttach, 
    aws_ec2_transit_gateway.hubtgw,
    aws_route_table_association.az1_dmzExt,
    aws_route_table_association.az1_mgmt,
    aws_instance.az1_dmz_bigip,
    aws_eip.eip_az1_dmz_external,
    aws_eip.eip_az1_dmz_mgmt,
  ]
  for_each = {
    bigipdmz1 = aws_instance.az1_dmz_bigip.public_ip
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
resource "aws_network_interface" "az2_dmz_mgmt" {
  depends_on      = [aws_security_group.sg_ext_mgmt]
  subnet_id       = aws_subnet.az2_mgmt.id
  private_ips     = [var.az2_dmzF5.mgmt]
  security_groups = [aws_security_group.sg_ext_mgmt.id]
}

resource "aws_network_interface" "az2_dmz_external" {
  depends_on      = [aws_security_group.sg_external]
  subnet_id       = aws_subnet.az2_dmzExt.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [var.az2_dmzF5.dmz_ext_self]
  security_groups = [aws_security_group.sg_external.id]
  source_dest_check = false
  tags = {
    f5_cloud_failover_label = var.dmz_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "null_resource" "az2_dmz_external_secondary_ips" {
  depends_on = [aws_network_interface.az2_dmz_external, aws_instance.az2_dmz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az2_dmz_external.id} --private-ip-addresses ${var.az2_dmzF5.dmz_ext_vip}
    EOF
  }
}

resource "aws_network_interface" "az2_dmz_internal" {
  depends_on      = [aws_security_group.sg_internal]
  subnet_id       = aws_subnet.az2_dmzInt.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [var.az2_dmzF5.dmz_int_self]
  security_groups = [aws_security_group.sg_internal.id]
  source_dest_check = false
  tags = {
    f5_cloud_failover_label = var.dmz_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "null_resource" "az2_dmz_internal_secondary_ips" {
  depends_on = [aws_network_interface.az2_dmz_internal, aws_instance.az2_dmz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az2_dmz_internal.id} --private-ip-addresses ${var.az2_dmzF5.dmz_int_vip}
    EOF
  }
}

resource "aws_eip" "eip_az2_dmz_mgmt" {
  depends_on                = [aws_network_interface.az2_dmz_mgmt, aws_internet_gateway.gw]
  vpc                       = true
  network_interface         = aws_network_interface.az2_dmz_mgmt.id
  associate_with_private_ip = var.az2_dmzF5.mgmt
}

resource "aws_eip" "eip_az2_dmz_external" {
  depends_on                = [aws_network_interface.az2_dmz_external, aws_internet_gateway.gw]
  vpc                       = true
  network_interface         = aws_network_interface.az2_dmz_external.id
  associate_with_private_ip = var.az2_dmzF5.dmz_ext_self
}

# BigIP 2
resource "aws_instance" "az2_dmz_bigip" {
  depends_on        = [aws_eip.eip_az2_dmz_mgmt, aws_subnet.az2_mgmt, aws_security_group.sg_ext_mgmt, aws_network_interface.az2_dmz_external, aws_network_interface.az2_dmz_internal, aws_network_interface.az2_dmz_mgmt]
  ami               = var.ami_f5image_name
  instance_type     = var.ami_dmz_f5instance_type
  availability_zone = "${var.aws_region}b"
  user_data         = data.template_file.az2_dmzF5_vm_onboard.rendered
  iam_instance_profile        = aws_iam_instance_profile.bigip-failover-extension-iam-instance-profile.name
  key_name          = "kp${var.tag_name}"
  root_block_device {
    delete_on_termination = true
  }
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.az2_dmz_mgmt.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.az2_dmz_external.id
  }
  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.az2_dmz_internal.id
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
    Name = "${var.tag_name}-${var.az2_dmzF5.hostname}"
  }
}

# Recycle/revoke eval keys (useful for demo purposes)
resource "null_resource" "revoke_eval_keys_upon_destroy_dmz2" {
  depends_on = [
    aws_route_table_association.az2_dmzExt,
    aws_route_table_association.az2_mgmt,
    aws_iam_policy_attachment.bigip-failover-extension-iam-policy-attach,
    aws_iam_policy.bigip-failover-extension-iam-policy,
    aws_security_group.sg_external,
    aws_key_pair.main,
    aws_route_table.DmzExtRt,
    aws_instance.az2_dmz_bigip,
    aws_eip.eip_az2_dmz_external,
    aws_eip.eip_az2_dmz_mgmt,
    aws_internet_gateway.gw
  ]
  for_each = {
    bigipdmz2 = aws_instance.az2_dmz_bigip.public_ip
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
data "template_file" "az1_dmzCluster_do_json" {
  template = "${file("${path.module}/dmz_clusterAcrossAZs_do.tpl.json")}"
  vars = {
    #Uncomment the following line for BYOL
    regkey         = var.dmz_lic1
    banner_color   = "red"
    Domainname     = var.f5Domainname
    host1          = var.az1_dmzF5.hostname
    host2          = var.az2_dmzF5.hostname
    local_host     = var.az1_dmzF5.hostname
    local_selfip1  = var.az1_dmzF5.dmz_ext_self
    local_selfip2  = var.az1_dmzF5.dmz_int_self
    #remote_selfip must be set to the same value on both bigips in order for HA clustering to work
    remote_selfip  = var.az1_dmzF5.mgmt
    mgmt_gw        = local.az1_mgmt_gw
    gateway        = local.az1_dmz_ext_gw
    dns_server     = var.dns_server
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
  }
}

# Render dmz DO declaration
resource "local_file" "az1_dmzCluster_do_file" {
  content  = data.template_file.az1_dmzCluster_do_json.rendered
  filename = "${path.module}/${var.az1_dmzCluster_do_json}"
}

## AZ2 Cluster DO Declaration
data "template_file" "az2_dmzCluster_do_json" {
  template = "${file("${path.module}/dmz_clusterAcrossAZs_do.tpl.json")}"
  vars = {
    #Uncomment the following line for BYOL
    regkey         = var.dmz_lic2
    banner_color   = "red"
    Domainname     = var.f5Domainname
    host1          = var.az1_dmzF5.hostname
    host2          = var.az2_dmzF5.hostname
    local_host     = var.az2_dmzF5.hostname
    local_selfip1  = var.az2_dmzF5.dmz_ext_self
    local_selfip2  = var.az2_dmzF5.dmz_int_self
    #remote_selfip must be set to the same value on both bigips in order for HA clustering to work
    remote_selfip  = var.az1_dmzF5.mgmt
    mgmt_gw        = local.az2_mgmt_gw
    gateway        = local.az2_dmz_ext_gw
    dns_server     = var.dns_server
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
  }
}

# Render DMZ DO declaration
resource "local_file" "az2_dmzCluster_do_file" {
  content  = data.template_file.az2_dmzCluster_do_json.rendered
  filename = "${path.module}/${var.az2_dmzCluster_do_json}"
}

# DMZ CF Declaration
data "template_file" "dmz_cf_json" {
  template = "${file("${path.module}/dmz_int_cloudfailover.tpl.json")}"

  vars = {
    cf_label = var.dmz_cf_label
    cf_cidr1 = var.az1_security_subnets.aip_dmz_int
    cf_cidr2 = var.az1_security_subnets.aip_dmzTransit_ext
    cf_nexthop1 = var.az1_dmzF5.dmz_ext_self
    cf_nexthop2 = var.az2_dmzF5.dmz_ext_self
    cf_nexthop3 = var.az1_dmzF5.dmz_int_self
    cf_nexthop4 = var.az2_dmzF5.dmz_int_self
  }
}

# Render DMZ CF Declaration
resource "local_file" "dmz_cf_file" {
  content  = data.template_file.dmz_cf_json.rendered
  filename = "${path.module}/${var.dmz_cf_json}"
}

# DMZ TS Declaration
data "template_file" "dmz_ts_json" {
  template = "${file("${path.module}/tsCloudwatch_ts.tpl.json")}"

  vars = {
    aws_region = var.aws_region
  }
}

# Render DMZ TS declaration
resource "local_file" "dmz_ts_file" {
  content  = data.template_file.dmz_ts_json.rendered
  filename = "${path.module}/${var.dmz_ts_json}"
}

# DMZ LogCollection AS3 Declaration
data "template_file" "dmz_logs_as3_json" {
  template = "${file("${path.module}/tsLogCollection_as3.tpl.json")}"

  vars = {

  }
}

# Render DMZ LogCollection AS3 declaration
resource "local_file" "dmz_logs_as3_file" {
  content  = data.template_file.dmz_logs_as3_json.rendered
  filename = "${path.module}/${var.dmz_logs_as3_json}"
}

# DMZ AS3 Declaration
data "template_file" "dmz_as3_json" {
  template = "${file("${path.module}/dmz_as3.tpl.json")}"

  vars = {
    backendvm_ip   = ""
    asm_policy_url = var.asm_policy_url
  }
}

# Render dmz AS3 declaration
resource "local_file" "dmz_as3_file" {
  content  = data.template_file.dmz_as3_json.rendered
  filename = "${path.module}/${var.dmz_as3_json}"
}


# Send declarations via REST API's
resource "null_resource" "az1_dmzF5_cluster_DO" {
  depends_on = [aws_instance.az1_dmz_bigip, local_file.az1_dmzCluster_do_file]
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -s -X ${var.rest_do_method} https://${aws_instance.az1_dmz_bigip.public_ip}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.az1_dmzCluster_do_json}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${aws_instance.az1_dmz_bigip.public_ip}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 120
    EOF
  }
}

resource "null_resource" "az2_dmzF5_cluster_DO" {
  depends_on = [aws_instance.az2_dmz_bigip, local_file.az2_dmzCluster_do_file]
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -s -X ${var.rest_do_method} https://${aws_instance.az2_dmz_bigip.public_ip}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.az2_dmzCluster_do_json}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${aws_instance.az2_dmz_bigip.public_ip}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 120
    EOF
  }
}

resource "null_resource" "dmzF5_CF" {
  depends_on	= [null_resource.az1_dmzF5_cluster_DO, null_resource.az2_dmzF5_cluster_DO]
  for_each = {
    bigip1 = aws_instance.az1_dmz_bigip.public_ip
    bigip2 = aws_instance.az2_dmz_bigip.public_ip
  }
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -s -X ${var.rest_do_method} https://${each.value}${var.rest_cf_uri} -u ${var.uname}:${var.upassword} -d @${var.dmz_cf_json}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${each.value}/mgmt/shared/cloud-failover/declare -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "success" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 120
    EOF
  }
}

resource "null_resource" "dmzF5_TS" {
  depends_on = [null_resource.dmzF5_CF]
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -H 'Content-Type: application/json' -k -X POST https://${aws_instance.az1_dmz_bigip.public_ip}${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @${var.dmz_ts_json}
    EOF
  }
}

resource "null_resource" "dmzF5_TS_LogCollection" {
  depends_on = [null_resource.dmzF5_TS]
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -H 'Content-Type: application/json' -k -X POST https://${aws_instance.az1_dmz_bigip.public_ip}${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @${var.dmz_logs_as3_json}
    EOF
  }
}
