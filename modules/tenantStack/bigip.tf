# Create and attach bigip tmm network interfaces
resource "aws_network_interface" "az1_tenant_mgmt" {
  depends_on      = [aws_security_group.sg_ext_mgmt]
  subnet_id       = aws_subnet.az1_tenant_mgmt.id
  private_ips     = [local.az1MgmtIp]
  security_groups = [aws_security_group.sg_ext_mgmt.id]
  #source_dest_check = false
}

resource "aws_network_interface" "az1_tenant_external" {
  depends_on      = [aws_security_group.sg_internal]
  subnet_id       = aws_subnet.az1_tenant_ext.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [local.az1ExtSelfIp]
  security_groups = [aws_security_group.sg_internal.id]
  source_dest_check = false
  tags              = {
    f5_cloud_failover_label = var.tenant_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

/*
resource "null_resource" "az1_tenant_external_secondary_ips" {
  depends_on = [aws_network_interface.az1_tenant_external, aws_instance.az1_tenant_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az1_tenant_external.id} --private-ip-addresses ${var.az1_tenantF5.tenant_ext_vip}
    EOF
  }
}
*/

resource "aws_network_interface" "az1_tenant_internal" {
  depends_on      = [aws_security_group.sg_internal]
  subnet_id       = aws_subnet.az1_tenant_int.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
#  private_ips     = [var.az1_tenantF5.tenant_int_self, var.az1_tenantF5.tenant_int_vip]
  private_ips     = [local.az1IntSelfIp]
  security_groups = [aws_security_group.sg_internal.id]
  source_dest_check = false
  tags              = {
    f5_cloud_failover_label = var.tenant_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

# Create elastic IP and map to "VIP" on external tenant nic
resource "aws_eip" "eip_az1_tenant_mgmt" {
  depends_on                = [aws_network_interface.az1_tenant_mgmt, aws_internet_gateway.tenantGw]
  vpc                       = true
  network_interface         = aws_network_interface.az1_tenant_mgmt.id
  associate_with_private_ip = local.az1MgmtIp
}

resource "aws_eip" "eip_az1_tenant_external" {
  depends_on                = [aws_network_interface.az1_tenant_external, aws_internet_gateway.tenantGw]
  vpc                       = true
  network_interface         = aws_network_interface.az1_tenant_external.id
  associate_with_private_ip = local.az1ExtSelfIp
}

#Big-IP 1
resource "aws_instance" "az1_tenant_bigip" {
  depends_on    = [aws_eip.eip_az1_tenant_mgmt, aws_subnet.az1_tenant_mgmt, aws_security_group.sg_ext_mgmt, aws_network_interface.az1_tenant_mgmt, aws_network_interface.az1_tenant_external, aws_network_interface.az1_tenant_internal]
  ami           = var.ami_f5image_name
  instance_type = var.az1_tenantF5.instance_type
  availability_zone           = "${var.aws_region}a"
  user_data     = data.template_file.az1_tenantF5_vm_onboard.rendered
  iam_instance_profile        = aws_iam_instance_profile.bigip-failover-extension-iam-instance-profile.name
  key_name      = "kp${var.tenant_name}"
  root_block_device {
    delete_on_termination = true
  }
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.az1_tenant_mgmt.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.az1_tenant_external.id
  }
  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.az1_tenant_internal.id
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
    Name = "${var.prefix}-${var.tenant_name}-${var.az1_tenantF5.hostname}"
  }
}


## AZ1 DO Declaration
data "template_file" "az1_tenantCluster_do_json" {
  template = file("${path.module}/tenant_clusterAcrossAZs_do.tpl.json")
  vars = {
    #Uncomment the following line for BYOL
    regkey         = var.az1_tenantF5.license
    banner_color   = "blue"
    Domainname     = var.f5Domainname
    host1          = var.az1_tenantF5.hostname
    host2          = var.az2_tenantF5.hostname
    local_host     = var.az1_tenantF5.hostname
    local_selfip1  = local.az1ExtSelfIp
    local_selfip2  = local.az1IntSelfIp
    #remote_selfip must be set to the same value on both bigips in order for HA clustering to work
    remote_selfip  = local.az1MgmtIp
    mgmt_gw        = local.az1_mgmt_gw
    gateway        = local.az1_tenant_ext_gw
    dns_server     = local.vpc_dns
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
    aip_ext_self   = local.aip_az1ExtSelfIp
    aip_ext_float  = local.aip_az1ExtFloatIp
    #app1_net        = "${local.app1_net}"
    #app1_net_gw     = "${local.app1_net_gw}"
  }
}
# Render tenant DO declaration
resource "local_file" "az1_tenantCluster_do_file" {
  content  = data.template_file.az1_tenantCluster_do_json.rendered
  filename = "${path.module}/${var.tenant_name}_${var.az1_tenantCluster_do_json}"
}


# Create and attach bigip tmm network interfaces
resource "aws_network_interface" "az2_tenant_mgmt" {
  depends_on      = [aws_security_group.sg_ext_mgmt]
  subnet_id       = aws_subnet.az2_tenant_mgmt.id
  private_ips     = [local.az2MgmtIp]
  security_groups = [aws_security_group.sg_ext_mgmt.id]
}

resource "aws_network_interface" "az2_tenant_external" {
  depends_on      = [aws_security_group.sg_internal]
  subnet_id       = aws_subnet.az2_tenant_ext.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [local.az2ExtSelfIp]
  security_groups = [aws_security_group.sg_internal.id]
  source_dest_check = false
  tags              = {
    f5_cloud_failover_label = var.tenant_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

/*
resource "null_resource" "az2_tenant_external_secondary_ips" {
  depends_on = [aws_network_interface.az2_tenant_external, aws_instance.az2_tenant_bigip]
  # Use the "aws ec2 assign-private-ip-addresses" command to correctly add secondary addresses to an existing network interface 
  #    -> Workaround for bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  #    -> "depends_on bigip" is required because the assign-private-ip-addresses command fails otherwise

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      aws ec2 assign-private-ip-addresses --region ${var.aws_region} --network-interface-id ${aws_network_interface.az2_tenant_external.id} --private-ip-addresses ${local.az2ExtVipIp}
    EOF
  }
}
*/

resource "aws_network_interface" "az2_tenant_internal" {
  depends_on      = [aws_security_group.sg_internal]
  subnet_id       = aws_subnet.az2_tenant_int.id
  #    bug: https://github.com/terraform-providers/terraform-provider-aws/issues/10674
  #    -> can't trust that the first IP will be set as the primary if you private_ips is set to more than one address...
  #    -> assumed that due to this bug, the primary and secondary addresses will be reversed
  private_ips     = [local.az2IntSelfIp]
  security_groups = [aws_security_group.sg_internal.id]
  source_dest_check = false
  tags              = {
    f5_cloud_failover_label = var.tenant_cf_label
  }
  lifecycle {
    ignore_changes = [
      private_ips,
    ]
  }  
}

resource "aws_eip" "eip_az2_tenant_mgmt" {
  depends_on                = [aws_network_interface.az2_tenant_mgmt, aws_internet_gateway.tenantGw]
  vpc                       = true
  network_interface         = aws_network_interface.az2_tenant_mgmt.id
  associate_with_private_ip = local.az2MgmtIp
}

resource "aws_eip" "eip_az2_tenant_external" {
  depends_on                = [aws_network_interface.az2_tenant_external, aws_internet_gateway.tenantGw]
  vpc                       = true
  network_interface         = aws_network_interface.az2_tenant_external.id
  associate_with_private_ip = local.az2ExtSelfIp
}


# BigIP 2
resource "aws_instance" "az2_tenant_bigip" {
  depends_on        = [aws_eip.eip_az2_tenant_mgmt, aws_subnet.az2_tenant_mgmt, aws_security_group.sg_ext_mgmt, aws_network_interface.az2_tenant_mgmt, aws_network_interface.az2_tenant_external, aws_network_interface.az2_tenant_internal]
  ami               = var.ami_f5image_name
  instance_type     = var.az2_tenantF5.instance_type
  availability_zone = "${var.aws_region}b"
  user_data         = data.template_file.az2_tenantF5_vm_onboard.rendered
  iam_instance_profile        = aws_iam_instance_profile.bigip-failover-extension-iam-instance-profile.name
  key_name          = "kp${var.tenant_name}"
  root_block_device {
    delete_on_termination = true
  }
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.az2_tenant_mgmt.id
  }
  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.az2_tenant_external.id
  }
  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.az2_tenant_internal.id
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
    Name = "${var.prefix}-${var.tenant_name}-${var.az2_tenantF5.hostname}"
  }
}


## AZ2 DO Declaration
data "template_file" "az2_tenantCluster_do_json" {
  template = file("${path.module}/tenant_clusterAcrossAZs_do.tpl.json")
  vars = {
    #Uncomment the following line for BYOL
    regkey         = var.az2_tenantF5.license
    banner_color   = "blue"
    Domainname     = var.f5Domainname
    host1          = var.az1_tenantF5.hostname
    host2          = var.az2_tenantF5.hostname
    local_host     = var.az2_tenantF5.hostname
    local_selfip1  = local.az2ExtSelfIp
    local_selfip2  = local.az2IntSelfIp
    #remote_selfip must be set to the same value on both bigips in order for HA clustering to work
    remote_selfip  = local.az1MgmtIp
    mgmt_gw        = local.az2_mgmt_gw
    gateway        = local.az2_tenant_ext_gw
    dns_server     = local.vpc_dns
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
    aip_ext_self   = local.aip_az2ExtSelfIp
    aip_ext_float  = local.aip_az1ExtFloatIp
    #app1_net        = "${local.app1_net}"
    #app1_net_gw     = "${local.app1_net_gw}"
  }
}

# Render tenant DO declaration
resource "local_file" "az2_tenantCluster_do_file" {
  content  = data.template_file.az2_tenantCluster_do_json.rendered
  filename = "${path.module}/${var.tenant_name}_${var.az2_tenantCluster_do_json}"
}

# Tenant CF Declaration
data "template_file" "tenant_cf_json" {
  template = file("${path.module}/tenant_cloudfailover.tpl.json")

  vars = {
    cf_label = var.tenant_cf_label
    cf_cidr1 = "0.0.0.0/0"
    cf_cidr1_nextHop1 = local.az1IntSelfIp
    cf_cidr1_nextHop2 = local.az2IntSelfIp
    cf_cidr2 = var.tenant_aip_cidr
    cf_cidr2_nextHop1 = local.az1ExtSelfIp
    cf_cidr2_nextHop2 = local.az2ExtSelfIp
  }
}

# Render DMZ CF Declaration
resource "local_file" "tenant_cf_file" {
  content  = data.template_file.tenant_cf_json.rendered
  filename = "${path.module}/${local.tenant_cf_json}"
}

# tenant TS Declaration
data "template_file" "tenant_ts_json" {
  template = file("${path.module}/tsCloudwatch_ts.tpl.json")

  vars = {
    aws_region = var.aws_region
  }
}

# Render tenant TS declaration
resource "local_file" "tenant_ts_file" {
  content  = data.template_file.tenant_ts_json.rendered
  filename = "${path.module}/${var.tenant_name}_${var.tenant_ts_json}"
}

# tenant LogCollection AS3 Declaration
data "template_file" "tenant_logs_as3_json" {
  template = file("${path.module}/tsLogCollection_as3.tpl.json")

  vars = {
    logStream = local.az1_cwLogStream
  }
}
# Render tenant LogCollection AS3 declaration
resource "local_file" "tenant_logs_as3_file" {
  content = data.template_file.tenant_logs_as3_json.rendered
  filename = "${path.module}/${var.tenant_name}_${var.tenant_logs_as3_json}"
}



# tenant AS3 Declaration
data "template_file" "tenant_as3_json" {
  template = file("${path.module}/tenant_as3.tpl.json")

  vars = {
    #backendvm_ip   = aws_instance.bastionHost[0].private_ip
    #asm_policy_url = var.asm_policy_url
    greNextHop = local.greNextHop
  }
}

# Render tenant AS3 declaration
resource "local_file" "tenant_as3_file" {
  content = data.template_file.tenant_as3_json.rendered
  filename = "${path.module}/${var.tenant_name}_${var.tenant_as3_json}"
}


resource "null_resource" "az1_tenantF5_DO" {
  depends_on = [aws_instance.az1_tenant_bigip]
  # Running DO REST API
  provisioner "file" {
    source = "${path.module}/${var.tenant_name}_${var.az1_tenantCluster_do_json}"
    destination = "/var/tmp/${var.az1_tenantCluster_do_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_tenant_bigip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -k -X ${var.rest_do_method} https://localhost${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.az1_tenantCluster_do_json}",
      "x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://localhost${var.rest_do_uri}/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep \"OK\" ); then break; fi; sleep 10; x=$(( $x + 1 )); done",
      "sleep 120",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_tenant_bigip.public_ip
    }
  }


}

resource "null_resource" "az2_tenantF5_DO" {
  depends_on = [aws_instance.az2_tenant_bigip]
  # Running DO REST API

  provisioner "file" {
    source = "${path.module}/${var.tenant_name}_${var.az2_tenantCluster_do_json}"
    destination = "/var/tmp/${var.az2_tenantCluster_do_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az2_tenant_bigip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-type: application/json' -k -X ${var.rest_do_method} https://localhost${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.az2_tenantCluster_do_json}",
      "x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://localhost${var.rest_do_uri}/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep \"OK\" ); then break; fi; sleep 10; x=$(( $x + 1 )); done",
      "sleep 120",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az2_tenant_bigip.public_ip
    }
  }
  
}

resource "null_resource" "tenantF5_CF" {
  depends_on	= [null_resource.az1_tenantF5_DO, null_resource.az2_tenantF5_DO, aws_s3_bucket.cfTenant]
  for_each = {
    bigip1 = aws_instance.az1_tenant_bigip.public_ip
    bigip2 = aws_instance.az2_tenant_bigip.public_ip
  }

  provisioner "file" {
    source = "${path.module}/${local.tenant_cf_json}"
    destination = "/var/tmp/${local.tenant_cf_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = each.value
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-type: application/json' -k -s -X ${var.rest_do_method} https://localhost${var.rest_cf_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${local.tenant_cf_json}",
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

resource "null_resource" "tenantF5_TS" {
  depends_on = [null_resource.az1_tenantF5_DO, null_resource.az2_tenantF5_DO]
  # Running CF REST API

  provisioner "file" {
    source = "${path.module}/${var.tenant_name}_${var.tenant_ts_json}"
    destination = "/var/tmp/${var.tenant_ts_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_tenant_bigip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-type: application/json' -k -X ${var.rest_ts_method} https://localhost${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.tenant_ts_json}",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_tenant_bigip.public_ip
    }
  }

}

resource "null_resource" "tenantF5_TS_LogCollection" {
  depends_on = [null_resource.tenantF5_TS]

  provisioner "file" {
    source = "${path.module}/${var.tenant_name}_${var.tenant_logs_as3_json}"
    destination = "/var/tmp/${var.tenant_logs_as3_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_tenant_bigip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -k -X ${var.rest_as3_method} https://localhost${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.tenant_logs_as3_json}",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_tenant_bigip.public_ip
    }
  }

}

#Tenant AS3 Declaration
resource "null_resource" "tenantF5_AS3_declaration" {
  depends_on = [null_resource.tenantF5_TS_LogCollection]

  provisioner "file" {
    source = "${path.module}/${var.tenant_name}_${var.tenant_as3_json}"
    destination = "/var/tmp/${var.tenant_as3_json}"

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_tenant_bigip.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-type: application/json' -k -X ${var.rest_as3_method} https://localhost${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/${var.tenant_as3_json}"
    ]

    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = aws_instance.az1_tenant_bigip.public_ip
    }
  }
}

# Configure Off-Box Analytics
resource "null_resource" "tenant_offBoxAnalytics" {
  depends_on = [null_resource.az1_tenantF5_DO, null_resource.az2_tenantF5_DO, null_resource.tenantF5_TS]
  for_each = {
    bigip1 = aws_instance.az1_tenant_bigip.public_ip
    bigip2 = aws_instance.az2_tenant_bigip.public_ip
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