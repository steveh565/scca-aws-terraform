output "VPC_DNS"             { value = "${local.vpc_dns}" }

output "az1_mgmt_subnet"     { value = "${local.az1MgmtSnet}" }
output "az2_mgmt_subnet"     { value = "${local.az2MgmtSnet}" }

output "az1_external_subnet" { value = "${local.az1ExtSnet}" }
output "az2_external_subnet" { value = "${local.az2ExtSnet}" }

output "az1_internal_subnet" { value = "${local.az1IntSnet}" }
output "az2_internal_subnet" { value = "${local.az2IntSnet}" }

output "az1_BigIP_mgmtAddr"  { value = "${local.az1MgmtIp}" }
output "az2_BigIP_mgmtAddr"  { value = "${local.az2MgmtIp}" }
output "az1_BigIP_extAddr"  { value = "${local.az1ExtSelfIp}" }
output "az2_BigIP_extAddr"  { value = "${local.az2ExtSelfIp}" }

output "az1_BigIP_aipSelfIp"  { value = "${local.aip_az1ExtSelfIp}" }
output "az2_BigIP_aipSelfIp"  { value = "${local.aip_az2ExtSelfIp}" }
output "BigIP_aipFloatIp"     { value = "${local.aip_az1ExtFloatIp}" }

output "GRE_LocalAddr"        { value = "${local.greTunLocAddr}" }
output "GRE_RemoteAddr"       { value = "${local.greTunRemAddr}" }
output "GRE_SelfIp"           { value = "${local.greSelfIp}" }
output "GRE_NextHop"          { value = "${local.greNextHop}" }