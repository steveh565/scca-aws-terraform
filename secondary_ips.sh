#!/bin/bash

paz="null_resource.az1_external_secondary_ips null_resource.az2_external_secondary_ips null_resource.az1_internal_secondary_ips null_resource.az2_internal_secondary_ips"
dmz="null_resource.az1_dmz_external_secondary_ips null_resource.az2_dmz_external_secondary_ips null_resource.az1_dmz_internal_secondary_ips null_resource.az2_dmz_internal_secondary_ips"
transit="null_resource.az1_transit_external_secondary_ips null_resource.az2_transit_external_secondary_ips null_resource.az1_transit_internal_secondary_ips null_resource.az2_transit_internal_secondary_ips"
eips="aws_eip.eip_az1_external aws_eip.eip_az2_external aws_eip.eip_az1_transit_external aws_eip.eip_az2_transit_external aws_eip.eip_az1_dmz_external aws_eip.eip_az2_dmz_external" 

for i in $paz $dmz $transit $eips; do 
    #echo ""
    #echo "terraform taint $i";
    #echo ""
    terraform taint $i;
done;

targets="";
for j in $paz $dmz $transit $eips; do 
    targets=$targets" -target=$j";
done;

#echo ""
#echo "terraform apply -auto-approve $targets";
terraform apply -auto-approve $targets;
#echo ""


#eip_targets="";
#for k in $eips; do 
#    eip_targets=$eip_targets" -target=$k";
#done;

#echo ""
#echo "terraform apply -auto-approve $eip_targets";
#terraform apply -auto-approve $eip_targets
#echo ""


echo "";
echo "Done!";
echo "";

