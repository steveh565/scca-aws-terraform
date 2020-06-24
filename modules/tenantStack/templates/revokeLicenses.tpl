#!/bin/bash

# BIG-IPS revokeLicense SCRIPT

for host in ${az1Mgmt} ${az2Mgmt}; do 
    ssh -oStrictHostKeyChecking=no admin@$host 'modify cli preference pager disabled display-threshold 0; revoke sys license';
done;

