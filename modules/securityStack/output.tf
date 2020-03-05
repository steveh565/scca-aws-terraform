output "Hub_Transit_Gateway_ID"     { value = aws_ec2_transit_gateway.hubtgw.id }
output "hubtgwRt_ID"                { value = aws_ec2_transit_gateway.hubtgw.association_default_route_table_id }
output "hubTgwAttach_ID"            { value = aws_ec2_transit_gateway_vpc_attachment.hubTgwAttach.id }

output "az1_pazF5_Mgmt_Addr"        { value = aws_instance.az1_paz_bigip.public_ip }
output "az2_pazF5_Mgmt_Addr"        { value = aws_instance.az2_paz_bigip.public_ip }

output "PAZ_Ingress_Public_EIP"     { value = aws_eip.eip_vip.public_ip }

output "az1_dmzF5_Mgmt_Addr"        { value = aws_instance.az1_dmz_bigip.public_ip }
output "az2_dmzF5_Mgmt_Addr"        { value = aws_instance.az2_dmz_bigip.public_ip }

output "az1_transitF5_Mgmt_Addr"    { value = aws_instance.az1_transit_bigip.public_ip }
output "az2_transitF5_Mgmt_Addr"    { value = aws_instance.az2_transit_bigip.public_ip }

output "az1_transit_int_gw"         { value = local.az1_transit_int_gw }
output "az2_transit_int_gw"         { value = local.az2_transit_int_gw }

output "TransitRt_ID"               { value = aws_route_table.TransitRt.id }