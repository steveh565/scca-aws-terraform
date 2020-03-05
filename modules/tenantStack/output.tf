output "VPC_DNS"             { value = local.vpc_dns }

output "tenant_vpc_cidr"     { value = var.tenant_vpc_cidr }
output "tenant_aip_cidr"     { value = var.tenant_aip_cidr }
output "tenant_vip_cidr"     { value = var.tenant_vip_cidr }

output "az1_mgmt_subnet"     { value = local.az1MgmtSnet }
output "az2_mgmt_subnet"     { value = local.az2MgmtSnet }

output "az1_external_subnet" { value = local.az1ExtSnet }
output "az2_external_subnet" { value = local.az2ExtSnet }

output "az1_internal_subnet" { value = local.az1IntSnet }
output "az2_internal_subnet" { value = local.az2IntSnet }

output "az1_BigIP_mgmtAddr"  { value = aws_eip.eip_az1_tenant_mgmt.public_ip }
output "az2_BigIP_mgmtAddr"  { value = aws_eip.eip_az2_tenant_mgmt.public_ip }

output "az1_BigIP_extAddr"   { value = local.az1ExtSelfIp }
output "az2_BigIP_extAddr"   { value = local.az2ExtSelfIp }

output "az1_BigIP_aipSelfIp" { value = local.aip_az1ExtSelfIp }
output "az2_BigIP_aipSelfIp" { value = local.aip_az2ExtSelfIp }
output "BigIP_aipFloatIp"    { value = local.aip_az1ExtFloatIp }

output "greTunLocAddr"       { value = local.greTunLocAddr }
output "greTunRemAddr"       { value = local.greTunRemAddr }
output "greSelfIp"           { value = local.greSelfIp }
output "greNextHop"          { value = local.greNextHop }

output "tenant_name"         { value = var.tenant_name }

output "tenant_TransitRt_ID" { value = aws_route_table.tenant_TransitRt.id }

output "tenant_az1_bigip_ID" { value = aws_instance.az1_tenant_bigip }

output "tenant_tgwAttach_ID" { value = aws_ec2_transit_gateway_vpc_attachment.tenantTgwAttach.id}
