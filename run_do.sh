#!/bin/bash

paz="null_resource.az1_pazF5_cluster_DO null_resource.az2_pazF5_cluster_DO local_file.az1_pazCluster_do_file local_file.az2_pazCluster_do_file"
dmz="null_resource.az1_dmzF5_DO null_resource.az2_dmzF5_DO local_file.az1_dmz_do_file local_file.az2_dmz_do_file"
transit="null_resource.az1_transitF5_DO null_resource.az1_transitF5_DO local_file.az1_transit_do_file local_file.az2_transit_do_file"

for i in $paz $dmz $transit; do 
    #echo ""
    #echo "terraform taint $i";
    #echo ""
    terraform taint $i;
done;

targets="";
for j in $paz $dmz $transit; do 
    targets=$targets" -target=$j";
done;

#echo ""
echo "terraform apply -auto-approve $targets";
#terraform apply -auto-approve $targets;
#echo ""

echo "";
echo "Done!";
echo "";

