# Deploy a Secure Remote Access solution


## Introduction

Use this Terraform code to deploy a WebTop service, with WebSSH, RDP and SSL VPN gateway services on a bigip.
APM configuration is done imperatively, hence the use of the file, tmsh and bash functions/commands.
This code is non idempotent (be cautious when applying more than once).


## Instructions

- Pass the appropriate variable values as parameters when calling this module from a parent terraform module.
example:

/code snippet
        module "f5SraWebPortal" {
        source = "./f5SraWebPortal"

        bigip_mgmt_public_ip = "52.139.83.189"
        bigip_vip_private_ip = "10.21.2.51"
        uname = "adminusername"
        upassword  = "adminuserspassword" 
        vlans_enabled = "/Common/external"
        }
code snippet/

- Run 'terraform init' and then 'terraform apply'.
- The APM tarball artifacts need to be refactored if to be deployed on a bigip version other than 15.0.
- Choose/set the value of the bigip_vip_private_ip carefully (especially if your bigip is in an HA cluster with auto-sync enabled).
- The resulting configuration does not include any authentication server definition (needs to be configured post deployment).



## Requirements


### Terraform Host

- Linux Bash Shell enviorment (Windows not supported at this time)
- Linux Terraform binary v0.12 


### BIG-IP

- version 15.0 (APM profile and policy archives are locked for v15.0 only).
- provisioned with at least LTM, iLX and APM.
- Applications services installed


### Terraform variables

Each value for the following required variables should/can be passed/set from the calling module as a parameter
- bigip_mgmt_public_ip   (only need to push the config against BIGIP1 because the cluster auto-sync will replicate config appropriately)
- bigip_vip_private_ip   (listener on bigip1 for the webtop, RDP, and webssh services)
- uname                  (priviledged bigip admin user)
- upassword              (priviledged bigip admin user's password)
- vlans_enabled          (optional variable allows overide of default /Common/external)


### Files (templates and RPM packages)

- profile_SRA_ZeroTrustSecureRemoteAccess.conf.tar      (some objects are defined with hardcoded IP addresses)
- policy_SRA_ZeroTrustSecureRemoteAccessPRP.conf.tar.gz    (URL branching rules are defined with harcoded IP addresses)
- BIG-IP-ILX-WebSSH2-0.2.8.tgz  (this one is required until we figure out how to leverage the licensed PUA feature)
- bigip_sra.tpl.json  (AS3 template to deploy the virtual server for the webtop with SSLVPN and RDPG services, and also the WebSSH virtual server on port 4439)



## Ideas for future enhancements

- Add documentation to describe the security controls that this solution addresses.
- Replace hardcoded SSL cert in AS3 declaration template with SSL certificates from let's encrypt.
- make the application name, partition name, virtual server description a variable instead of hard-coding to "SRA"
- instead of waiting for APM to support declarative configuration via REST, consider unziping the APM policy tarbal files, templatizing the IP's and names, then re-zip?




### Copyright

Copyright 


### License
Copyright 2019 F5 Networks Inc.
This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
If a copy of the MPL was not distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.


#### Contributor License Agreement
