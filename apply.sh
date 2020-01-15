#!/bin/bash

dirString="maz tenant"

#build the security inspection vpc
hubOut=`terraform apply -auto-approve`
tgwId=`echo $hubOut |grep "Output" |grep -i "tgw-" | cut -d '=' -f 2`

if [ -z $tgwId ]; then
	echo "FATAL: Did not capture AWS Transit Gateway ID of HUB TGW!";
	echo "terraform output: ";
	echo "";
	echo $hubOut | tr '.' '\n';
	exit 1;
fi


# Build the tenant VPCs
for i in $dirString ; do (
	cd $i;
	terraform import aws_ec2_transit_gateway.hubtgw $tgwId &&
	terraform apply -auto-approve;
	cd ../;
) done;



