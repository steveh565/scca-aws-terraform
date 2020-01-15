# Deploy a Secure Remote Access solution with Ansible


## Introduction

This repo contains a set of Terraform templates to deploy a Secure Cloud Architecture reference implementation in AWS. 

## Security Controls

The following Government of Canada ITSG-33 security controls can be met through configuration of this template:

- AC-2, AC-2(1), AC-3(7), AC-4, AC-2(5), AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-12, AC-17, 
- AU-2, AU-8, AU-8(1), AU-8(2), AU-9(2), AU-12(2), 
- CM-5, CM-6, CM-7, 
- CP-9, CP-10(5), CP-4(4), CP-9(1),
- IA-2, IA-2(8), IA-5(1), IA-5(2), IA-5(6), 
- SC-5, SC-7, SC-7(11), SC-7(18), SC-8, SC-8(1), SC-10, SC-12, SC-13, SC-24,
- SI-2, SI-4, SI-4(4), SI-4(10), 

## Terraform Template Information

To be filled in later:

- Update vars.tf with valid License Keys, SSH Keys
- Update setAwsCreds.sh 
- Run the included shell scripts to deploy
- init.sh: Initialize terraform
- validate.sh: Validate terraform template syntax (useful if you're making changes)
- apply.sh: Instantiate the deployment in AWS

## Ideas for future enhancements

- Add documentation to describe the security controls that this solution addresses
- Encorporate automatic SSL certificate service (i.e., let's encrypt?)
- Add a play to output/print out all relevant FQDN's and IP addresses at the end

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
