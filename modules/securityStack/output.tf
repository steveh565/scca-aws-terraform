output "Hub_Transit_Gateway_ID"     { value = "${aws_ec2_transit_gateway.hubtgw.id}" }

output "az1_pazF5_Mgmt_Addr"        { value = "${aws_instance.az1_paz_bigip.public_ip}" }
output "az2_pazF5_Mgmt_Addr"        { value = "${aws_instance.az2_paz_bigip.public_ip}" }

output "PAZ_Ingress_Public_EIP"     { value = "${aws_eip.eip_vip.public_ip}" }

output "az1_dmzF5_Mgmt_Addr"        { value = "${aws_instance.az1_dmz_bigip.public_ip}" }
output "az2_dmzF5_Mgmt_Addr"        { value = "${aws_instance.az2_dmz_bigip.public_ip}" }

output "az1_transitF5_Mgmt_Addr"    { value = "${aws_instance.az1_transit_bigip.public_ip}" }
output "az2_transitF5_Mgmt_Addr"    { value = "${aws_instance.az2_transit_bigip.public_ip}" }

output "TransitRt_ID"        { value = "${aws_route_table.TransitRt.id}" }