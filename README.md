# Deploy a Secure Remote Access solution with Ansible


## Introduction

This repo contains a set of Terraform templates to deploy a Secure Cloud Architecture reference implementation in AWS. 

## Security Controls

The following Government of Canada ITSG security controls can be met through configuration of this template:

- AC-2, AC-2(1), AC-3(7), AC-4, AC-2(5), AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-12, AC-17, 
- AU-2, AU-8, AU-8(1), AU-8(2), AU-9(2), AU-12(2), 
- CM-5, CM-6, CM-7, 
- CP-9, CP-10(5), CP-4(4), CP-9(1),
- IA-2, IA-2(8), IA-5(1), IA-5(2), IA-5(6), 
- SC-5, SC-7, SC-7(11), SC-7(18), SC-8, SC-8(1), SC-10, SC-12, SC-13, SC-24,
- SI-2, SI-4, SI-4(4), SI-4(10), 

## Terraform Template Information

- Update vars.tf with valid License Keys, SSH Keys, AWS API Creds
- Run the included shell scripts to deploy
-- init.sh: Initialize terraform
-- validate.sh: Validate terraform template syntax (useful if you're making changes)
-- apply.sh: Instantiate the deployment in AWS
- create 4x Cloudwatch dashboards, and inport the dashboard definitions for each one, found in the Cloudwatch folder

## Ideas for future enhancements

- Incorporate automatic SSL certificate service (i.e., let's encrypt?)
- Incorporate Shape Fraud Prevention services (Install the iRule & DG, stage it for use)
- Incorporate SRA webtop portal solution deployment for each tenant F5 pair.
- Add automation to complete the initial configuration of all devices
 - TS, DO, AS3, CF, onboarding script
- ~Update f5 BigIP IAM Role to include permissions for S3 or Cloudwatch - whichever consumer TS is configured to send to.~
 - remove reference to AWS creds in TS declaration template
- Remove all references to creds in vars.tf
- ~Add VPC Endpoints to each VPC: S3, Cloudwatch (logs), EC2~
- ~Add CF tags (CF failover label & f5_self_ips) to managed route tables and EIPs~
- ~Add CF tags (cf_failover_label) to tmm NICs (eth1, eth2)~
 - ~Add CF Tags to vars.tf~
- ~Upgrade to use CF-1.0.0 RPM (vars.tf URL)~
- ~Upgrade to use Latest AnO RPMs (vars.tf URL)~
- Fix up depends_on mess for Big-IP instance creation
 - AWS ca-central-1 is slow: VM boot and onboard takes forever and often isn't finished before DO declaration fires
- Develop patch for tg-active.sh failover script to decrease "think" time in CF failover trigger???
- Implement a proper prefix based object naming convention 
- Implement resource group tags
- ~Develop visualization of TS data stored in Cloudwatch~
- Implement bigip_instance terraform module with options for 
 - 3-NIC, 4-NIC and 8-NIC configurations
  - 3-NIC: Standard tenant configuration: 2x VE-200M-BT (mgmt/external/internal)
  - 4-NIC: Standard GC-CAP configuration: 2x HP-VE-10G-BT (mgmt/external/internal/logging)
  - 8-NIC to have 5 external NICs to support additional EIP mappsings: 2x HP-VE-10G-BT (mgmt/external_x5/internal/logging)
   - 5 x 30 EIPs == 150 EIPS * 10 Applications / EIP == Unique 1500 Application Flows
- Implement Tenant VPC terraform module
- Clean up GC-CAP VPC creation scripts (terraform)




## Requirements

- Linux Bash Shell enviorment (Windows not supported at this time)
- Linux Terraform binary v0.12 
- AWS Subscription IAM Access ID, Access Key (API creds)
- SSH private and public keys (for CLI authentication)
- 4x F5 HP-VE BEST Bundle License Keys with IPI, IPS options
- 2x F5 1Gbps VE BEST Bundle License Keys with IPI, IPS options
- 4x F5 200Mbps VE BEST Bundle License Keys


---



### Copyright

Copyright 

### License


#### Contributor License Agreement

