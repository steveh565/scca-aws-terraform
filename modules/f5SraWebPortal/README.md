# Deploy a Secure Remote Access solution


## Introduction

Use this Terraform code to deploy a WebTop service, with WebSSH, RDP and SSL VPN gateway services on a bigip.
The APM profile tarball artifact does not include any authentication server definition (needs to be configured post deployment).
Because APM cannot be configured declaratively with AS3, imperative commands have to be used (hence the use of the file, tmsh and bash commands below).
Because of the use of imperative commands, this code is non idempotent (be careful if applying more than once).


## Instructions

Update the default variable values below or pass the appropriate values via the parent calling terraform module.
Run 'terraform init' and then 'terraform apply'.
The APM tarball artifacts need to be refactored if to be deployed on a bigip version other than 15.0.
Choose/set the value of the bigip_vip_private_ip carefully (especially if your bigip is in an HA cluster with auto-sync enabled).

Note: The APM profile tarball artifacts in this repo do not include any authentication server definition (needs to be configured post deployment).


## Requirements


## Terraform Host

- Linux Bash Shell enviorment (Windows not supported at this time)
- Linux Terraform binary v0.12 
- AWS Subscription IAM Access ID, Access Key (API creds)
- SSH private and public keys (for CLI authentication)

### BIG-IP

- version 15.0 (APM profile and policy archives are locked for v15.0 only).
- provisioned with at least LTM, iLX and APM.
- Applications services installed

### Terraform variables

Each value for the following required variables should/can be passed/set from the calling module as a parameter
- bigip_mgmt_public_ip   (only need to push the config against BIGIP1 because the cluster auto-sync will replicate config appropriately)
- bigip_vip_private_ip   (listener on bigip1 for the webtop, RDP, and webssh services... use 0.0.0.0 to simplify HA across AZ in AWS, or adjust .json template to add private vip for other bigip if required)
- uname                  (priviledged bigip admin user)
- upassword              (priviledged bigip admin user's password)

### Files (templates and RPM packages)

- profile_ZT_SRA_ZeroTrustSecureRemoteAccess.conf.tar      (some objects are defined with hardcoded IP addresses)
- policy_ZT_SRA_ZeroTrustSecureRemoteAccessPRP.conf.tar.gz    (URL branching rules are defined with harcoded IP addresses)
- BIG-IP-ILX-WebSSH2-0.2.8.tgz  (this one is required until we figure out how to leverage the licensed PUA feature)
- bigip_zt_sra.tpl.json  (AS3 template to deploy the virtual server for the webtop with SSLVPN and RDPG services, and also the WebSSH virtual server on port 4439)



## Ideas for future enhancements

- Add documentation to describe the security controls that this solution addresses.
- Replace hardcoded SSL cert in AS3 declaration template with SSL certificates from let's encrypt.
- modify the vip variable to be a list (that's what the AS3 declaration needs for the "virtual adress" value, and two IP addresses are required for HA across AZ's in AWS)
- make the application name, partition name, virtual server description a variable instead of hard-coding to "ZT_SRA"
- modify the vip variable to be a list (that's what the AS3 declaration needs for the "virtual adress" value, and two IP addresses are required for HA across AZ's in AWS)
- make the application name, partition name, virtual server description a variable instead of hard-coding to "ZT_SRA"
- instead of waiting for APM to support declarative configuration via REST, consider unziping the APM policy tarbal files, templatizing the IP's and names, then re-zip?
- make the SRA webtop work with a 0.0.0.0/0 destination address (suspect the APM policies don't like 0.0.0.0/0).




### Copyright

Copyright 


### License
Copyright 2019 F5 Networks Inc.
This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
If a copy of the MPL was not distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/.


#### Contributor License Agreement
