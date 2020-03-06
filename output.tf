output "GCCAP_PAZ_Ingress_Public_EIP"     { value = module.securityStack.PAZ_Ingress_Public_EIP }

output "CAP_az1_pazF5_Mgmt_Addr"        { value = module.securityStack.az1_pazF5_Mgmt_Addr }
output "CAP_az2_pazF5_Mgmt_Addr"        { value = module.securityStack.az2_pazF5_Mgmt_Addr }

output "CAP_az1_dmzF5_Mgmt_Addr"        { value = module.securityStack.az1_dmzF5_Mgmt_Addr }
output "CAP_az2_dmzF5_Mgmt_Addr"        { value = module.securityStack.az2_dmzF5_Mgmt_Addr }

output "CAP_az1_transitF5_Mgmt_Addr"    { value = module.securityStack.az1_transitF5_Mgmt_Addr }
output "CAP_az2_transitF5_Mgmt_Addr"    { value = module.securityStack.az2_transitF5_Mgmt_Addr }

output "Tenant_MAZ_az1_tenantF5_Mgmt_Addr"    { value = module.tenantStack_MAZ.az1_BigIP_mgmtAddr }
output "Tenant_MAZ_az2_tenantF5_Mgmt_Addr"    { value = module.tenantStack_MAZ.az1_BigIP_mgmtAddr }

output "Tenant_CSD_az1_tenantF5_Mgmt_Addr"    { value = module.tenantStack_CSD.az1_BigIP_mgmtAddr }
output "Tenant_CSD_az2_tenantF5_Mgmt_Addr"    { value = module.tenantStack_CSD.az1_BigIP_mgmtAddr }
