output "PAZ_Ingress_Public_EIP"     { value = module.securityStack.PAZ_Ingress_Public_EIP }

output "az1_pazF5_Mgmt_Addr"        { value = module.securityStack.az1_pazF5_Mgmt_Addr }
output "az2_pazF5_Mgmt_Addr"        { value = module.securityStack.az2_pazF5_Mgmt_Addr }

output "az1_dmzF5_Mgmt_Addr"        { value = module.securityStack.az1_dmzF5_Mgmt_Addr }
output "az2_dmzF5_Mgmt_Addr"        { value = module.securityStack.az2_dmzF5_Mgmt_Addr }

output "az1_transitF5_Mgmt_Addr"    { value = module.securityStack.az1_transitF5_Mgmt_Addr }
output "az2_transitF5_Mgmt_Addr"    { value = module.securityStack.az2_transitF5_Mgmt_Addr }
