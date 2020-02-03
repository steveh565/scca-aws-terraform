output "az1_mgmt_subnet"     { value = "${local.az1MgmtSnet}" }
output "az2_mgmt_subnet"     { value = "${local.az2MgmtSnet}" }

output "az1_external_subnet" { value = "${local.az1ExtSnet}" }
output "az2_external_subnet" { value = "${local.az2ExtSnet}" }

output "az1_internal_subnet" { value = "${local.az1IntSnet}" }
output "az2_internal_subnet" { value = "${local.az2IntSnet}" }
