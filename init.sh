#!/bin/bash

dirString="maz tenant"

echo "WARNING: This will initialize the current terraform working directory..."
echo "Press CTRL+C to abort. Press any other Key to continue..."
read input junk

for i in $dirString ; do (
	cd $i;
	terraform init;
	cd ../
) done;

terraform init
