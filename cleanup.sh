#!/bin/bash

dirString=". maz tenant"

echo "WARNING: This will remove all Terraform state artifacts..."
echo "Press CTRL+C to abort. Press any other Key to continue..."
read input junk

for i in $dirString ; do (
	rm -rf $i/.terraform ;
	rm -rf $i/terraform.tfstate;
	rm -rf $i/terraform.tfstate.backup;
) done;


