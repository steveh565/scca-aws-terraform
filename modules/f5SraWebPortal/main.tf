# the values should be passed from tge calling parent module as parameters, but for testing purposes, you can set the values here.
variable bigip_mgmt_public_ip { default = "" }
variable bigip_vip_private_ip { default = "0.0.0.0" }
variable uname { default = "" }
variable upassword { default = "" }

provider "bigip" {
  address  = var.bigip_mgmt_public_ip
  username = var.uname
  password = var.upassword
}

// Using  provisioner to upload iLX NodeJS tar file and create iLX workspace and iLX plugin on bigip1 for WebSSH
resource "null_resource" "bigip_create_ilx_plugin" {

  provisioner "file" {
    source      = "BIG-IP-ILX-WebSSH2-0.2.8.tgz"
    destination = "/var/tmp/BIG-IP-ILX-WebSSH2-0.2.8.tgz"
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "tmsh create ilx workspace WebSSH2",
      "cd /var/ilx/workspaces/Common/WebSSH2",
      "tar -zxvf /var/tmp/BIG-IP-ILX-WebSSH2-0.2.8.tgz",
      "tmsh create ilx plugin WebSSH2_plugin from-workspace WebSSH2",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }
}

// publish Zero Trust Secure Remote Access (ZT_SRA) AS3 declaration to BIGIP1
// config_name is only used to set the identity of as3 resource which is unique for resource.
// LTM objects, iLX plugins and APM objects are automatically synched across the HA cluster members.
// In AWS HA across AZ's, each bigip device in the HA cluster has their own unique private VIP addresses.
// The Cloud Failover extension is configured to remap the EIP's or routes accordingly upon failover events
resource "bigip_as3" "bigip_zt_sra" {
  depends_on  = [null_resource.bigip_create_ilx_plugin]
  as3_json    = templatefile("bigip_zt_sra.tpl.json", { Bigip1VipPrivateIp = var.bigip_vip_private_ip })
  config_name = "zt_sra"
}

// Using  provisioner to upload and attach APM policies to above bigip_zt_sra virtual server on bigip1
resource "null_resource" "bigip_upload_apm_policies" {
  depends_on = [bigip_as3.bigip_zt_sra]

  provisioner "file" {
    source      = "profile_ZT_SRA_ZeroTrustSecureRemoteAccess.conf.tar"
    destination = "/var/tmp/profile_ZT_SRA_ZeroTrustSecureRemoteAccess.conf.tar"
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }

  provisioner "file" {
    source      = "policy_ZT_SRA_ZeroTrustSecureRemoteAccessPRP.conf.tar.gz"
    destination = "/var/tmp/policy_ZT_SRA_ZeroTrustSecureRemoteAccessPRP.conf.tar.gz"
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "ng_import -s /var/tmp/profile_ZT_SRA_ZeroTrustSecureRemoteAccess.conf.tar ZeroTrustSecureRemoteAccess -p ZT_SRA",
      "ng_import -s -t access_policy /var/tmp/policy_ZT_SRA_ZeroTrustSecureRemoteAccessPRP.conf.tar.gz ZeroTrustSecureRemoteAccessPRP -p ZT_SRA",
      "tmsh modify /apm profile access /ZT_SRA/ZeroTrustSecureRemoteAccess-RDPGatewayRAP generation-action increment",
      "tmsh modify /apm profile access /ZT_SRA/ZeroTrustSecureRemoteAccess generation-action increment",
      "tmsh create apm profile connectivity zt_sra_cp",
      "tmsh create apm profile vdi /ZT_SRA/zt_sra_vdi",
      "tmsh modify ltm profile http /ZT_SRA/ZT_SRA_Webtop/webtop_http response-chunking default-value",
      "tmsh modify ltm profile http /ZT_SRA/ZT_SRA_Webtop/webtop_http request-chunking default-value",
      "tmsh create ltm profile rewrite /ZT_SRA/zt_sra_rewriteprofile defaults-from rewrite-portal location-specific false split-tunneling false request { insert-xforwarded-for enabled rewrite-headers enabled } response { rewrite-content enabled rewrite-headers enabled }",
      "tmsh modify ltm virtual /ZT_SRA/ZT_SRA_Webtop/serviceMain profiles add {/ZT_SRA/ZeroTrustSecureRemoteAccess} profiles add {zt_sra_vdi} profiles add {zt_sra_cp} profiles add {zt_sra_rewriteprofile} per-flow-request-access-policy /ZT_SRA/ZeroTrustSecureRemoteAccessPRP",
      "tmsh save sys config",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }
}
