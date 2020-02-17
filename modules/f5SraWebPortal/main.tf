# the values should be passed from tge calling parent module as parameters, but for testing purposes, you can set the values here.
variable bigip_mgmt_public_ip { default = "" }
variable bigip_vip_private_ip { default = "" }
// variable uname { default = "" }
// variable upassword { default = "" }
// variable rest_as3_uri { default "" }

locals {
  #the following tmsh apm commands are required to adjust the IP addresses which are hardcoded for the WebSSH service (target and per-request policy URL branches to allow or block SSH to specific target hosts... because those IP's are hardcoded in the APM policy tarball artifacts)
  tmshAPMcommand1 = "tmsh modify apm resource portal-access /SRA/WebSSH { application-uri \"https://${var.bigip_vip_private_ip}:4439/ssh/host/10.21.1.50?port=22&header=CLASSIFIED&headerBackground=red\" customization-group /SRA/WebSSH_resource_web_app_customization items modify { item { paths /ssh/host/10.21.1.50 subnet ${var.bigip_vip_private_ip}/32 sso /SRA/SRA_sso }}}"
  tmshAPMcommand2 = "tmsh modify apm policy policy-item /SRA/SecureRemoteAccessPRP_act_url_branching_perrq { rules { { caption /ssh/host/10.* expression \"expr {[mcget {perflow.branching.url}] contains '/ssh/host/10.'}\" next-item /SRA/SecureRemoteAccessPRP_end_allow } { caption fallback next-item /SRA/SecureRemoteAccessPRP_end_allow }}}"
}


// provider "bigip" {
// #  address  = var.bigip_mgmt_public_ip
//   address  = "1.1.1.1"
//   username = var.uname
//   password = var.upassword
// }

// Using  provisioner to upload iLX NodeJS tar file and create iLX workspace and iLX plugin on bigip1 for WebSSH
resource "null_resource" "bigip_create_ilx_plugin" {

  provisioner "file" {
    source      = "${path.module}/BIG-IP-ILX-WebSSH2-0.2.8.tgz"
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
      "tar -zxvf /var/tmp/BIG-IP-ILX-WebSSH2-0.2.8.tgz  >> /var/log/extract-webssh-nodejs-package.log",
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
// resource "bigip_as3" "bigip_sra" {
//   depends_on  = [null_resource.bigip_create_ilx_plugin]
//   as3_json    = templatefile("${path.module}/bigip_sra.tpl.json", { Bigip1VipPrivateIp = var.bigip_vip_private_ip })
//   config_name = "sra"
// }

# Render SRA AS3 declaration
resource "local_file" "bigip_sra_as3_file" {
  content     = templatefile("${path.module}/bigip_sra.tpl.json", { Bigip1VipPrivateIp = var.bigip_vip_private_ip })
  filename    = "${path.module}/bigip_sra_as3.json"
}

resource "null_resource" "bigip_sra_as3" {
  depends_on  = [local_file.bigip_sra_as3_file]
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -H 'Content-Type: application/json' -k -X POST https://${var.bigip_mgmt_public_ip}${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @${path.module}/bigip_sra_as3.json
    EOF
  }
}


// Using  provisioner to upload and attach APM policies to above bigip_zt_sra virtual server on bigip1
resource "null_resource" "bigip_upload_apm_policies" {
#  depends_on = [bigip_as3.bigip_sra]
  depends_on = [null_resource.bigip_sra_as3]
  provisioner "file" {
    source      = "${path.module}/profile_SecureRemoteAccessAP.conf.tar"
    destination = "/var/tmp/profile_SecureRemoteAccess.conf.tar"
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }

  provisioner "file" {
    source      = "${path.module}/policy_SecureRemoteAccessPRP.conf.tar"
    destination = "/var/tmp/policy_SecureRemoteAccessPRP.conf.tar"
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "ng_import -s /var/tmp/profile_SecureRemoteAccess.conf.tar SecureRemoteAccessAP -p SRA",
      "ng_import -s -t access_policy /var/tmp/policy_SecureRemoteAccessPRP.conf.tar SecureRemoteAccessPRP -p SRA",
      local.tmshAPMcommand1,
      local.tmshAPMcommand2,
      "tmsh modify /apm profile access /SRA/SecureRemoteAccessAP-RDPGatewayRAP generation-action increment",
      "tmsh modify /apm profile access /SRA/SecureRemoteAccessAP generation-action increment",
      "tmsh create apm profile connectivity /SRA/sra_cp",
      "tmsh create apm profile vdi /SRA/sra_vdi",
      "tmsh modify ltm profile http /SRA/SRA_Webtop/webtop_http response-chunking default-value",
      "tmsh modify ltm profile http /SRA/SRA_Webtop/webtop_http request-chunking default-value",
      "tmsh create ltm profile rewrite /SRA/sra_rewriteprofile defaults-from rewrite-portal location-specific false split-tunneling false request { insert-xforwarded-for enabled rewrite-headers enabled } response { rewrite-content enabled rewrite-headers enabled }",
      "tmsh modify ltm virtual /SRA/SRA_Webtop/serviceMain profiles add {/SRA/SecureRemoteAccessAP} profiles add {/SRA/sra_vdi} profiles add {/SRA/sra_cp} profiles add {/SRA/sra_rewriteprofile} per-flow-request-access-policy /SRA/SecureRemoteAccessPRP",
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