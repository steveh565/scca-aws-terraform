#!/bin/bash

# BIG-IPS revokeLicense SCRIPT

for host in ${az1PazMgmt} ${az2PazMgmt} ${az1DmzMgmt} ${az2DmzMgmt} ${az1TransitMgmt} ${az2TransitMgmt}; do 
    ssh -oStrictHostKeyChecking=no admin@$host 'modify cli preference pager disabled display-threshold 0; revoke sys license';
done;