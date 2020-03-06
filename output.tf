output "PAZ_Ingress_Public_EIP"     { value = module.securityStack.PAZ_Ingress_Public_EIP }

output "az1_pazF5_Mgmt_Addr"        { value = module.securityStack.az1_pazF5_Mgmt_Addr }
output "az2_pazF5_Mgmt_Addr"        { value = module.securityStack.az2_pazF5_Mgmt_Addr }

output "az1_dmzF5_Mgmt_Addr"        { value = module.securityStack.az1_dmzF5_Mgmt_Addr }
output "az2_dmzF5_Mgmt_Addr"        { value = module.securityStack.az2_dmzF5_Mgmt_Addr }

output "az1_transitF5_Mgmt_Addr"    { value = module.securityStack.az1_transitF5_Mgmt_Addr }
output "az2_transitF5_Mgmt_Addr"    { value = module.securityStack.az2_transitF5_Mgmt_Addr }

output "MAZ_az1_tenantF5_Mgmt_Addr"    { value = module.tenantStack_MAZ.az1_BigIP_mgmtAddr }
output "MAZ_az2_tenantF5_Mgmt_Addr"    { value = module.tenantStack_MAZ.az1_BigIP_mgmtAddr }

output "CSD_az1_tenantF5_Mgmt_Addr"    { value = module.tenantStack_CSD.az1_BigIP_mgmtAddr }
output "CSD_az2_tenantF5_Mgmt_Addr"    { value = module.tenantStack_CSD.az1_BigIP_mgmtAddr }
