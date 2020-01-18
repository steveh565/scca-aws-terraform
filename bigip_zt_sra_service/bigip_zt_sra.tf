/*
Copyright 2019 F5 Networks Inc.
This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
If a copy of the MPL was not distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/

/*
########## depenencies, required variables/parameters:
 bigip_mgmt_public_ip   (the value of this variable should be passed from calling module as a parameter)
 bigip2_mgmt_public_ip   (the value of this variable should be passed from calling module as a parameter)
 bigip_vip_private_ip   (the value of this variable should be passed from calling module as a parameter)
 bigip2_vip_private_ip   (the value of this variable should be passed from calling module as a parameter)
 upassword              (the value of this variable should be passed from calling module as a parameter)
 uname                  (the value of this variable should be passed from calling module as a parameter)
 create_tf_admin_user.txt       (json data to create tf_admin user via REST API)
 profile_ZT_SRA_ZeroTrustSecureRemoteAccess.conf.tar.gz      (some objects are defined with hardcoded IP addresses)
 policy_ZT_SRA_ZeroTrustSecureRemoteAccessPRP.conf.tar.gz    (URL branching rules are defined with harcoded IP addresses)
 BIG-IP-ILX-WebSSH2-0.2.8.tgz  (this one is required until we figure out how to leverage the licensed PUA feature)
 AS3 template bigip_zt_sra.json  (deploys the virtual server for the webtop with SSLVPN and RDPG services, and also the WebSSH virtual server on port 4439)
*/

variable uname { default = "admin" }
variable upassword { default = "Canada12345" }
variable bigip_mgmt_public_ip { default = "15.222.47.31" }
variable bigip_vip_private_ip { default = "10.10.2.233" }
variable bigip2_mgmt_public_ip { default = "15.222.169.158" }
variable bigip2_vip_private_ip { default = "10.10.102.129" }

provider "bigip" {
  address  = var.bigip_mgmt_public_ip
  username = var.uname
  password = var.upassword
}

provider "bigip" {
  alias    = "bigip2"
  address  = var.bigip2_mgmt_public_ip
  username = var.uname
  password = var.upassword
}

// Using  provisioner to create a temporary tf_admin user account on bigip. This temporary user \
// account is required with bash terminal access for uploading files to bigip and for running \
// bash commands on the bigip.
resource "null_resource" "bigip_create_tf_admin_user" {

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -sku ${var.uname}:${var.upassword} -H "Content-Type: application/json" -X POST https://${var.bigip_mgmt_public_ip}/mgmt/tm/auth/user -d @create_tf_admin_user.txt
    EOF
  }
}

// Using  provisioner to upload iLX NodeJS tar file and create iLX workspace and iLX plugin on bigip1 (auto-synch takes care of bigip2)
resource "null_resource" "bigip_create_ilx_plugin" {
  depends_on = [null_resource.bigip_create_tf_admin_user]

  provisioner "file" {
    source      = "BIG-IP-ILX-WebSSH2-0.2.8.tgz"
    destination = "/var/tmp/BIG-IP-ILX-WebSSH2-0.2.8.tgz"
    connection {
      type     = "ssh"
      password = "Canada12345"
      user     = "tf_admin"
      host     = var.bigip_mgmt_public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "tmsh create ilx workspace WebSSH2",
      "cd /var/ilx/workspaces/Common/WebSSH2",
      "tar -zxvf /var/tmp/BIG-IP-ILX-WebSSH2-0.2.8.tgz",
      "tmsh create ilx plugin WebSSH2_plugin from-workspace WebSSH2",
      "tmsh save sys config",
    ]
    connection {
      type     = "ssh"
      password = "Canada12345"
      user     = "tf_admin"
      host     = var.bigip_mgmt_public_ip
    }
  }
}

// publish Zero Trust Secure Remote Access (ZT_SRA) AS3 declaration to BIGIP1 (auto-synch takes care of bigip2)
// config_name is used to set the identity of as3 resource which is unique for resource.
// Assuming iLX rules and APM objects are automatically synched across the HA cluster members,
// ... each bigip device in the HA cluster has its own unique VIP address,
// therefore different AS3 declarations are required
resource "bigip_as3" "bigip_zt_sra" {
  depends_on  = [null_resource.bigip_create_ilx_plugin]
  as3_json    = templatefile("bigip_zt_sra.json", { Bigip1VipPrivateIp = var.bigip_vip_private_ip, WebAppName = "ZT_SRA" })
  config_name = "zt_sra"
}
resource "bigip_as3" "bigip2_zt_sra" {
  depends_on = [bigip_as3.bigip_zt_sra]
  #override default bigip provider just for this resource, just to configure the vip with a different IP on bigip2...
  provider    = bigip.bigip2
  as3_json    = templatefile("bigip_zt_sra.json", { Bigip1VipPrivateIp = var.bigip2_vip_private_ip, WebAppName = "ZT_SRA" })
  config_name = "zt_sra"
}

// Using  provisioner to upload and attach APM policies to above bigip_zt_sra virtual server on bigip1 (auto-synch takes care of bigip2)
resource "null_resource" "bigip_upload_apm_policies" {
  depends_on = [bigip_as3.bigip_zt_sra]

  provisioner "file" {
    source      = "profile_ZT_SRA_ZeroTrustSecureRemoteAccess.conf.tar.gz"
    destination = "/var/tmp/profile_ZT_SRA_ZeroTrustSecureRemoteAccess.conf.tar.gz"
    connection {
      type     = "ssh"
      password = "Canada12345"
      user     = "tf_admin"
      host     = var.bigip_mgmt_public_ip
    }
  }

  provisioner "file" {
    source      = "policy_ZT_SRA_ZeroTrustSecureRemoteAccessPRP.conf.tar.gz"
    destination = "/var/tmp/policy_ZT_SRA_ZeroTrustSecureRemoteAccessPRP.conf.tar.gz"
    connection {
      type     = "ssh"
      password = "Canada12345"
      user     = "tf_admin"
      host     = var.bigip_mgmt_public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "ng_import -s /var/tmp/profile_ZT_SRA_ZeroTrustSecureRemoteAccess.conf.tar.gz ZeroTrustSecureRemoteAccess -p ZT_SRA",
      "ng_import -s -t access_policy /var/tmp/policy_ZT_SRA_ZeroTrustSecureRemoteAccessPRP.conf.tar.gz ZeroTrustSecureRemoteAccessPRP -p ZT_SRA",
      "tmsh modify /apm profile access /ZT_SRA/ZeroTrustSecureRemoteAccess-RDPGatewayRAP generation-action increment",
      "tmsh modify /apm profile access /ZT_SRA/ZeroTrustSecureRemoteAccess generation-action increment",
      "tmsh create apm profile connectivity zt_sra_cp",
      "tmsh create apm profile vdi /ZT_SRA/zt_sra_vdi",
      "tmsh create ltm profile rewrite /ZT_SRA/zt_sra_rewriteprofile defaults-from rewrite-portal location-specific false split-tunneling false request { insert-xforwarded-for enabled rewrite-headers enabled } response { rewrite-content enabled rewrite-headers enabled }",
      "tmsh modify ltm virtual /ZT_SRA/ZT_SRA_Webtop/serviceMain profiles add {/ZT_SRA/ZeroTrustSecureRemoteAccess} profiles add {zt_sra_vdi} profiles add {zt_sra_cp} profiles add {zt_sra_rewriteprofile} per-flow-request-access-policy /ZT_SRA/ZeroTrustSecureRemoteAccessPRP",
      "tmsh save sys config",
    ]
    connection {
      type     = "ssh"
      password = "Canada12345"
      user     = "tf_admin"
      host     = var.bigip_mgmt_public_ip
    }
  }
}

// Using  provisioner to delete temporary tf_admin user account with bash terminal access on bigip1 (auto-synch takes care of bigip2)
resource "null_resource" "bigip_delete_tf_admin_user" {
  depends_on = [null_resource.bigip_upload_apm_policies]

  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -sku ${var.uname}:${var.upassword} -H "Content-Type: application/json" -X DELETE https://${var.bigip_mgmt_public_ip}/mgmt/tm/auth/user/tf_admin
    EOF
  }
}