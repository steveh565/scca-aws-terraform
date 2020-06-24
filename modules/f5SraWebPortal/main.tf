# the values should be passed from tge calling parent module as parameters, but for testing purposes, you can set the values here.
variable uname { description = "Valid username for target BigIP" }
variable upassword { description = "Valid password for target BigIP" }
#there must be an easy way to query aws API to deterime the maz bigip's public management IP address...
variable bigip_mgmt_public_ip { default = "35.182.123.82" }
variable bigip_vip_private_ip { default = "10.11.1.111" }
variable ssh_target_ip { default = "10.11.0.11" }
variable rest_as3_uri {default = "/mgmt/shared/appsvcs/declare"}
variable vlans_enabled { default = "/Common/external"}
variable juiceshop_vip_private_ip { description = "JuiceShop service VIP" }
variable juiceShop1 { description = "az1 JuiceShop host" }
variable juiceShop2 { description = "az2 JuiceShop host" }
variable tenant_name { description = "unique prefix" }

locals {
  #the following tmsh apm commands are required to adjust the IP addresses which are hardcoded for the WebSSH service (target and per-request policy URL branches to allow or block SSH to specific target hosts... because those IP's are hardcoded in the APM policy tarball artifacts)
  tmshAPMcommand1 = "tmsh modify apm resource portal-access /SRA/WebSSH { application-uri \"https://${var.bigip_vip_private_ip}:4439/ssh/host/${var.ssh_target_ip}?port=22&header=CLASSIFIED&headerBackground=red\" customization-group /SRA/WebSSH_resource_web_app_customization items modify { item { paths /ssh/host/${var.ssh_target_ip} subnet ${var.bigip_vip_private_ip}/32 sso /SRA/SRA_sso }}}"
  tmshAPMcommand2 = "tmsh modify apm policy policy-item /SRA/SecureRemoteAccessPRP_act_url_branching_perrq { rules { { caption /ssh/host/10.* expression \"expr {[mcget {perflow.branching.url}] contains '/ssh/host/10.'}\" next-item /SRA/SecureRemoteAccessPRP_end_allow } { caption fallback next-item /SRA/SecureRemoteAccessPRP_end_allow }}}"
}


// Using  provisioner to upload iLX NodeJS tar file and create iLX workspace and iLX plugin on bigip1 for WebSSH
resource "null_resource" "bigip_create_ilx_plugin" {
  // # hardcode a wait/sleep to give time for the bigip onboarding process to complete (otherwise "tmsh create ilx" command will fail)
  // provisioner "local-exec" {
  //   command = <<-EOF
  //     #!/bin/bash
  //     sleep 600
  //   EOF
  // }  

  provisioner "file" {
    source      = "${path.module}/files/BIG-IP-ILX-WebSSH2-0.2.8.tgz"
    destination = "/var/tmp/BIG-IP-ILX-WebSSH2-0.2.8.tgz"
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }

  # Upload WebSSH2 NodeJS package and wait for the "listen on" vlan to exist (otherwise, the subsequent AS3 declaration will fail)
  provisioner "remote-exec" {
    inline = [
      "x=1; while [ $x -le 30 ]; RESULT=$(tmsh list /net self |grep -c ${var.vlans_enabled}); do if [[ $RESULT > 0 ]]; then break; fi; echo 'SRAwebPortal: Waiting for ${var.vlans_enabled} to be created...'; sleep 60; x=$(( $x + 1 )); done",
      "tmsh create ilx workspace WebSSH2",
      "cd /var/ilx/workspaces/Common/WebSSH2",
      "tar -zxvf /var/tmp/BIG-IP-ILX-WebSSH2-0.2.8.tgz  >> /var/log/extract-webssh-nodejs-package.log",
      "tmsh create ilx plugin WebSSH2_plugin from-workspace WebSSH2"
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
    on_failure = continue
  }
}

// publish Zero Trust Secure Remote Access (ZT_SRA) AS3 declaration to BIGIP1
// LTM objects, iLX plugins and APM objects are automatically synched across the HA cluster members.
// In AWS HA across AZ's, each bigip device in the HA cluster has their own unique private VIP addresses.
// The Cloud Failover extension is configured to remap the EIP's or routes accordingly upon failover events.
# Render SRA AS3 declaration
resource "local_file" "bigip_sra_as3_file" {
  content     = templatefile("${path.module}/templates/bigip_sra.tpl.json", { Bigip1VipPrivateIp = var.bigip_vip_private_ip, vlans_enabled = var.vlans_enabled, Bigip2VipPrivateIp = var.juiceshop_vip_private_ip, juiceShop1 = var.juiceShop1, juiceShop2 = var.juiceShop2 })
  filename    = "${path.module}/files/${var.tenant_name}_bigip_sra_as3.json"
}

resource "null_resource" "bigip_sra_as3" {
  depends_on  = [local_file.bigip_sra_as3_file, null_resource.bigip_create_ilx_plugin]

  provisioner "file" {
    source      = "${path.module}/${var.tenant_name}_bigip_sra_as3.json"
    destination = "/var/tmp/bigip_sra_as3.json"
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "curl -H 'Content-Type: application/json' -k -X POST https://localhost${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @/var/tmp/bigip_sra_as3.json",
    ]
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }
}


// Using  provisioner to upload and attach APM policies to above bigip_zt_sra virtual server on bigip1
resource "null_resource" "bigip_upload_apm_policies" {
#  depends_on = [bigip_as3.bigip_sra]
  depends_on = [null_resource.bigip_sra_as3]
  provisioner "file" {
    source      = "${path.module}/files/profile_SecureRemoteAccessAP.conf.tar"
    destination = "/var/tmp/profile_SecureRemoteAccess.conf.tar"
    connection {
      type     = "ssh"
      password = var.upassword
      user     = var.uname
      host     = var.bigip_mgmt_public_ip
    }
  }

  provisioner "file" {
    source      = "${path.module}/files/policy_SecureRemoteAccessPRP.conf.tar"
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
    on_failure = continue
  }
}
