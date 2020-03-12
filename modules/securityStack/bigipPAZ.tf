# Create and attach bigip tmm network interfaces
resource "aws_network_interface" "az1_mgmt" {
  depends_on      = [aws_security_group.sg_ext_mgmt]
  subnet_id       = aws_subnet.az1_mgmt.id
  private_ips     = [local.az1PazMgmtIp]
  security_groups = [aws_security_group.sg_ext_mgmt.id]
}

resource "aws_network_interface" "az1_external" {
  depends_on      = [aws_security_group.sg_external]
  subnet_id       = aws_subnet.az1_ext.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [local.az1PazExtSelfIp]
  security_groups = [aws_security_group.sg_external.id]
  source_dest_check = false
  tags = {
    f5_cloud_failover_label = var.gccap_cf_label
    VIPS = "${local.az1PazExtVipIp},${local.az2PazExtVipIp}"
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "null_resource" "az1_external_secondary_ips" {
  depends_on = [aws_network_interface.az1_external, aws_instance.az1_paz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az1_external.id} --private-ip-addresses ${local.az1PazExtVipIp}
    EOF
  }
}

resource "aws_network_interface" "az1_internal" {
  depends_on      = [aws_security_group.sg_internal]
  subnet_id       = aws_subnet.az1_dmzExt.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [local.az1PazIntSelfIp]
  security_groups = [aws_security_group.sg_internal.id]
  source_dest_check = false
  tags = {
    f5_cloud_failover_label = var.gccap_cf_label
  }  
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

/*
resource "null_resource" "az1_internal_secondary_ips" {
  depends_on = [aws_network_interface.az1_internal, aws_instance.az1_paz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az1_internal.id} --private-ip-addresses ${var.az1_pazF5.dmz_ext_vip}
    EOF
  }
}
*/

# Create elastic IP and map to "VIP" on external paz nic
resource "aws_eip" "eip_vip" {
  depends_on                = [aws_network_interface.az1_external, aws_internet_gateway.gw, null_resource.az1_external_secondary_ips]
  vpc                       = true
  network_interface         = aws_network_interface.az1_external.id
  associate_with_private_ip = local.az1PazExtVipIp
  tags = {
    f5_cloud_failover_label = var.gccap_cf_label
  }
  lifecycle {    
		ignore_changes = all
  } 
}

resource "aws_eip" "eip_az1_mgmt" {
  depends_on                = [aws_network_interface.az1_mgmt, aws_internet_gateway.gw]
  vpc                       = true
  network_interface         = aws_network_interface.az1_mgmt.id
  associate_with_private_ip = local.az1PazMgmtIp
}

resource "aws_eip" "eip_az1_external" {
  depends_on                = [aws_network_interface.az1_external, aws_internet_gateway.gw]
  vpc                       = true
  network_interface         = aws_network_interface.az1_external.id
  associate_with_private_ip = local.az1PazExtSelfIp
}

#Big-IP 1
resource "aws_instance" "az1_paz_bigip" {
  depends_on                  = [aws_eip.eip_az1_mgmt, aws_subnet.az1_mgmt, aws_security_group.sg_ext_mgmt, aws_network_interface.az1_external, aws_network_interface.az1_internal, aws_network_interface.az1_mgmt]
  ami                         = var.ami_f5image_name
  instance_type               = var.az1_pazF5.instance_type
  availability_zone           = "${var.aws_region}a"
  user_data                   = data.template_file.az1_pazF5_vm_onboard.rendered
  iam_instance_profile        = aws_iam_instance_profile.bigip-failover-extension-iam-instance-profile.name
  key_name                    = "kp${var.tag_name}"
  source_dest_check           = false
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
    connection {
      host     = self.public_ip
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "until grep -q 'TS is Ready' ${var.onboard_log}; do sleep 60; done; sleep 60"
    ]
  }

  tags = {
    Name = "${var.tag_name}-${var.az1_pazF5.hostname}"
  }
}


# Create and attach bigip tmm network interfaces
resource "aws_network_interface" "az2_mgmt" {
  depends_on      = [aws_security_group.sg_ext_mgmt]
  subnet_id       = aws_subnet.az2_mgmt.id
  private_ips     = [local.az2PazMgmtIp]
  security_groups = [aws_security_group.sg_ext_mgmt.id]
}

resource "aws_network_interface" "az2_external" {
  depends_on      = [aws_security_group.sg_external]
  subnet_id       = aws_subnet.az2_ext.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [local.az2PazExtSelfIp]
  security_groups = [aws_security_group.sg_external.id]
  source_dest_check = false
  tags = {
    f5_cloud_failover_label = var.gccap_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "null_resource" "az2_external_secondary_ips" {
  depends_on = [aws_network_interface.az2_external, aws_instance.az2_paz_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az2_external.id} --private-ip-addresses ${local.az2PazExtVipIp}
    EOF
  }
}

resource "aws_network_interface" "az2_internal" {
  depends_on      = [aws_security_group.sg_internal]
  subnet_id       = aws_subnet.az2_dmzExt.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [local.az2PazIntSelfIp]
  security_groups = [aws_security_group.sg_internal.id]
  source_dest_check = false
  tags = {
    f5_cloud_failover_label = var.gccap_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "aws_eip" "eip_az2_mgmt" {
  depends_on                = [aws_network_interface.az2_mgmt, aws_internet_gateway.gw]
  vpc                       = true
  network_interface         = aws_network_interface.az2_mgmt.id
  associate_with_private_ip = local.az2PazMgmtIp
}

resource "aws_eip" "eip_az2_external" {
  depends_on                = [aws_network_interface.az2_external, aws_internet_gateway.gw]
  vpc                       = true
  network_interface         = aws_network_interface.az2_external.id
  associate_with_private_ip = local.az2PazExtSelfIp
}


# BigIP 2
resource "aws_instance" "az2_paz_bigip" {
  depends_on                  = [aws_eip.eip_az2_mgmt, aws_subnet.az2_mgmt, aws_security_group.sg_ext_mgmt, aws_network_interface.az2_external, aws_network_interface.az2_internal, aws_network_interface.az2_mgmt]
  ami                         = var.ami_f5image_name
  instance_type               = var.az2_pazF5.instance_type
  availability_zone           = "${var.aws_region}b"
  user_data                   = data.template_file.az2_pazF5_vm_onboard.rendered
  iam_instance_profile        = aws_iam_instance_profile.bigip-failover-extension-iam-instance-profile.name
  key_name                    = "kp${var.tag_name}"
  source_dest_check           = false
  root_block_device {
    delete_on_termination = true
  }
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.az2_mgmt.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.az2_external.id
  }
  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.az2_internal.id
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
      "until grep -q 'TS is Ready' ${var.onboard_log}; do sleep 60; done; sleep 60"
    ]
  }

  tags = {
    Name = "${var.tag_name}-${var.az2_pazF5.hostname}"
  }
}

## AZ1 Cluster DO Declaration
data "template_file" "az1_pazCluster_do_json" {
  template = "${file("${path.module}/paz_clusterAcrossAZs_do.tpl.json")}"
  vars = {
    #Uncomment the following line for BYOL
    regkey         = var.az1_pazF5.license
    banner_color   = "red"
    Domainname     = var.f5Domainname
    host1          = var.az1_pazF5.hostname
    host2          = var.az2_pazF5.hostname
    local_host     = var.az1_pazF5.hostname
    local_selfip1  = local.az1PazExtSelfIp
    local_selfip2  = local.az1PazIntSelfIp
    #remote_selfip must be set to the same value on both bigips in order for HA clustering to work
    remote_selfip  = local.az1PazMgmtIp
    mgmt_gw        = local.az1_mgmt_gw
    gateway        = local.az1_paz_ext_gw
    dns_server     = local.vpc_dns
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
    aip_int_self   = local.aip_az1PazIntSelfIp
    aip_int_float  = local.aip_az1PazIntFloatIp
  }
}

# Render PAZ DO declaration
resource "local_file" "az1_pazCluster_do_file" {
  content     = data.template_file.az1_pazCluster_do_json.rendered
  filename    = "${path.module}/${var.az1_pazCluster_do_json}"
}

## AZ2 Cluster DO Declaration
data "template_file" "az2_pazCluster_do_json" {
  template = "${file("${path.module}/paz_clusterAcrossAZs_do.tpl.json")}"
  vars = {
    #Uncomment the following line for BYOL
    regkey         = var.az2_pazF5.license
    banner_color   = "red"
    Domainname     = var.f5Domainname
    host1          = var.az1_pazF5.hostname
    host2          = var.az2_pazF5.hostname
    local_host     = var.az2_pazF5.hostname
    local_selfip1  = local.az2PazExtSelfIp
    local_selfip2  = local.az2PazIntSelfIp
    #remote_selfip must be set to the same value on both bigips in order for HA clustering to work
    remote_selfip  = local.az1PazMgmtIp
    mgmt_gw        = local.az2_mgmt_gw
    gateway        = local.az2_paz_ext_gw
    dns_server     = local.vpc_dns
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
    aip_int_self   = local.aip_az2PazIntSelfIp
    aip_int_float  = local.aip_az1PazIntFloatIp
  }
}

# Render PAZ DO declaration
resource "local_file" "az2_pazCluster_do_file" {
  content     = data.template_file.az2_pazCluster_do_json.rendered
  filename    = "${path.module}/${var.az2_pazCluster_do_json}"
}

# PAZ CF Declaration
data "template_file" "paz_cf_json" {
  template = "${file("${path.module}/paz_int_cloudfailover.tpl.json")}"

  vars = {
    cap_cf_label = var.gccap_cf_label
    cf_label = var.paz_cf_label

    cf_cidr1 = local.aipPazIntSnet
    cf_cidr1_nextHop1 = local.az1PazIntSelfIp
    cf_cidr1_nextHop2 = local.az2PazIntSelfIp
    
    cf_cidr2 = "0.0.0.0/0"
    cf_cidr2_nextHop1 = local.az1PazIntSelfIp
    cf_cidr2_nextHop2 = local.az2PazIntSelfIp

  }
}

# Render PAZ CF Declaration
resource "local_file" "paz_cf_file" {
  content  = data.template_file.paz_cf_json.rendered
  filename = "${path.module}/${var.paz_cf_json}"
}

# PAZ TS Declaration
data "template_file" "paz_ts_json" {
  template = "${file("${path.module}/tsCloudwatch_ts.tpl.json")}"

  vars = {
    aws_region = var.aws_region
    logStream = local.az1_paz_cwLogStream
  }
}

# Render PAZ TS declaration
resource "local_file" "paz_ts_file" {
  content  = data.template_file.paz_ts_json.rendered
  filename = "${path.module}/${var.paz_ts_json}"
}

# PAZ LogCollection AS3 Declaration
data "template_file" "paz_logs_as3_json" {
  template = "${file("${path.module}/tsLogCollection_as3.tpl.json")}"

  vars = {
    
  }
}

# Render PAZ LogCollection AS3 declaration
resource "local_file" "paz_logs_as3_file" {
  content  = data.template_file.paz_logs_as3_json.rendered
  filename = "${path.module}/${var.paz_logs_as3_json}"
}

# PAZ AS3 Declaration
data "template_file" "paz_as3_json" {
  template = "${file("${path.module}/paz_as3.tpl.json")}"

  vars = {
    aip_az1PazIntFloatIp = local.aip_az1PazIntFloatIp
    asm_policy_url = var.asm_policy_url
  }
}

# Render PAZ AS3 declaration
resource "local_file" "paz_as3_file" {
  content  = data.template_file.paz_as3_json.rendered
  filename = "${path.module}/${var.paz_as3_json}"
}


# Send declarations via REST API's
resource "null_resource" "az1_pazF5_DO" {
  depends_on	= [aws_instance.az1_paz_bigip, local_file.az1_pazCluster_do_file]

  provisioner "file" {
    source = "${path.module}/${var.az1_pazCluster_do_json}"
    destination = "/var/tmp/${var.az1_pazCluster_do_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_paz_bigip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-type: application/json' -k -X ${var.rest_do_method} https://localhost${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.az1_pazCluster_do_json}",
      "x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://localhost${var.rest_do_uri}/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep \"OK\" ); then break; fi; sleep 10; x=$(( $x + 1 )); done",
      "sleep 120",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_paz_bigip.public_ip
    }
  }
}

resource "null_resource" "az2_pazF5_DO" {
  depends_on    = [aws_instance.az2_paz_bigip, local_file.az2_pazCluster_do_file]

  provisioner "file" {
    source = "${path.module}/${var.az2_pazCluster_do_json}"
    destination = "/var/tmp/${var.az2_pazCluster_do_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az2_paz_bigip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-type: application/json' -k -X ${var.rest_do_method} https://localhost${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.az2_pazCluster_do_json}",
      "x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://localhost${var.rest_do_uri}/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep \"OK\" ); then break; fi; sleep 10; x=$(( $x + 1 )); done",
      "sleep 120",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az2_paz_bigip.public_ip
    }
  }
}

resource "null_resource" "pazF5_CF" {
  depends_on	= [null_resource.az1_pazF5_DO, null_resource.az2_pazF5_DO, aws_s3_bucket.cfPaz]
  for_each = {
    bigip1 = aws_instance.az1_paz_bigip.public_ip
    bigip2 = aws_instance.az2_paz_bigip.public_ip
  }

  provisioner "file" {
    source = "${path.module}/${var.paz_cf_json}"
    destination = "/var/tmp/${var.paz_cf_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = each.value
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-type: application/json' -k -s -X ${var.rest_do_method} https://localhost${var.rest_cf_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.paz_cf_json}",
      "x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://localhost${var.rest_cf_uri} -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep 'success' ); then break; fi; sleep 10; x=$(( $x + 1 )); done; sleep 120"
    ]

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = each.value
    }
  }
}

resource "null_resource" "pazF5_TS" {
  depends_on = [null_resource.pazF5_CF]

  provisioner "file" {
    source = "${path.module}/${var.paz_ts_json}"
    destination = "/var/tmp/${var.paz_ts_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_paz_bigip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-type: application/json' -k -X ${var.rest_ts_method} https://localhost${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.paz_ts_json}",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_paz_bigip.public_ip
    }
  }
}

resource "null_resource" "pazF5_TS_LogCollection" {
  depends_on = [null_resource.pazF5_TS]

  provisioner "file" {
    source = "${path.module}/${var.paz_logs_as3_json}"
    destination = "/var/tmp/${var.paz_logs_as3_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_paz_bigip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-type: application/json' -k -X ${var.rest_as3_method} https://localhost${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.paz_logs_as3_json}",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_paz_bigip.public_ip
    }
  }
}

#Paz AS3 Declaration
resource "null_resource" "pazF5_AS3_declaration" {
  depends_on = [null_resource.pazF5_TS_LogCollection]

  provisioner "file" {
    source = "${path.module}/${var.paz_as3_json}"
    destination = "/var/tmp/${var.paz_as3_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_paz_bigip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-type: application/json' -k -X ${var.rest_as3_method} https://localhost${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.paz_as3_json}"
    ]

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_paz_bigip.public_ip
    }
  }
}

# Configure Off-Box Analytics
resource "null_resource" "paz_offBoxAnalytics" {
  depends_on = [null_resource.az1_pazF5_DO, null_resource.az2_pazF5_DO, null_resource.pazF5_TS]
  for_each = {
    bigip1 = aws_instance.az1_paz_bigip.public_ip
    bigip2 = aws_instance.az2_paz_bigip.public_ip
  }
  provisioner "remote-exec" {
    connection {
      host     = each.value
      type     = "ssh"
      user     = var.uname
      password = var.upassword
    }
    when = create
    inline = [
      "tmsh modify analytics global-settings { offbox-protocol tcp offbox-tcp-addresses add { 127.0.0.1 } offbox-tcp-port 6514 use-offbox enabled }"
    ]
    on_failure = continue
  }
}