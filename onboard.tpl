#!/bin/bash

# BIG-IPS ONBOARD SCRIPT

LOG_FILE=${onboard_log}

if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
else
    #if file exists, exit as only want to run once
    exit
fi

exec 1>$LOG_FILE 2>&1

# CHECK TO SEE NETWORK IS READY
CNT=0
while true
do
  STATUS=$(curl -s -k -I https://github.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! VE is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

sleep 30

### TMSH onboarding commands

# admin user
echo "set creds"
cat <<-EOF | tmsh -q
create cli transaction;
create /auth user ${uname} password ${upassword} shell bash partition-access replace-all-with { all-partitions { role admin } };
submit cli transaction
EOF

# mgmt
echo "set system"
cat <<-EOF | tmsh -q
create cli transaction;
modify /sys global-settings mgmt-dhcp disabled; 
modify /sys db config.allow.rfc3927 value enable;
submit cli transaction
EOF

echo "set management networking"
#cat <<-EOF | tmsh -q
#create cli transaction;
tmsh delete /sys management-route default;
tmsh delete /sys management-ip ${mgmt_ip}/24; 
tmsh create /sys management-ip ${mgmt_ip}/24; 
tmsh create /sys management-route default network default gateway ${mgmt_gw};
tmsh modify /sys dns name-servers replace-all-with { ${vpc_dns} } search replace-all-with { f5.com }
#submit cli transaction
#EOF


# LOCAL_ONLY
echo "set LOCAL_ONLY partition"
cat <<-EOF | tmsh -q
create cli transaction;
create /auth partition LOCAL_ONLY; 
modify /sys folder /LOCAL_ONLY device-group none traffic-group /Common/traffic-group-local-only; 
submit cli transaction
EOF

# Base Networking
echo "set TMM base networking"
#cat <<-EOF | tmsh -q
#create cli transaction;
tmsh create net vlan external interfaces add { 1.1 } mtu 1500;
tmsh create net self external-self address ${ext_self}/24 vlan external;
tmsh create net vlan internal interfaces add { 1.2 } mtu 1500;
tmsh create net self internal-self address ${int_self}/24 vlan internal;
tmsh create /net route /LOCAL_ONLY/default network default gw ${gateway}; 
tmsh create /sys management-route /LOCAL_ONLY/aws_API_route network 169.254.169.254 gateway ${mgmt_gw};
#submit cli transaction
#EOF

# Enable off-box AVR telemetry
modify analytics global-settings { offbox-protocol tcp offbox-tcp-addresses add { 127.0.0.1 } offbox-tcp-port 6514 use-offbox enabled }

#tmsh modify /auth user admin password ${upassword}
#create /cm device-group failoverGroup devices replace-all-with { transitF5vm01.f5labs.gc.ca { set-sync-leader } transitF5vm02.f5labs.gc.ca } type sync-failover auto-sync enabled save-on-auto-sync false network-failover enabled full-load-on-sync false asm-sync disabled
# CHECK TO SEE NETWORK IS READY AGAIN AFTER RECONFIGURING ROUTES
CNT=0
while true
do
  STATUS=$(curl -s -k -I https://github.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! VE is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

sleep 30

### DOWNLOAD ONBOARDING PKGS
# Could be pre-packaged or hosted internally

admin_username='${uname}'
admin_password='${upassword}'
CREDS="admin:"$admin_password
# Telemetry Streaming
TS_URL='${TS_URL}'
TS_FN=$(basename "$TS_URL")
# Declarative Onboarding
DO_URL='${DO_onboard_URL}'
DO_FN=$(basename "$DO_URL")
# Application Services
AS3_URL='${AS3_URL}'
AS3_FN=$(basename "$AS3_URL")
# Cloud Failover
CF_URL='${CF_URL}'
CF_FN=$(basename "$CF_URL")

mkdir -p ${libs_dir}
mkdir -p /var/config/rest/downloads

echo -e "\n"$(date) "Download TS Pkg"
curl -L -o ${libs_dir}/$TS_FN $TS_URL

echo -e "\n"$(date) "Download Declarative Onboarding Pkg"
curl -L -o ${libs_dir}/$DO_FN $DO_URL

echo -e "\n"$(date) "Download Cloud-Failover Pkg"
curl -L -o ${libs_dir}/$CF_FN $CF_URL

echo -e "\n"$(date) "Download AS3 Pkg"
curl -L -o ${libs_dir}/$AS3_FN $AS3_URL

# Copy the RPM Pkg to the file location
cp ${libs_dir}/*.rpm /var/config/rest/downloads/

# Install Telemetry Streaming Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$TS_FN\"}"
echo -e "\n"$(date) "Install TS Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

sleep 10

# Install Declarative Onboarding Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$DO_FN\"}"
echo -e "\n"$(date) "Install DO Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

sleep 10

# Install Cloud-Failover Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$CF_FN\"}"
echo -e "\n"$(date) "Install CF Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

sleep 10

# Install AS3 Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$AS3_FN\"}"
echo -e "\n"$(date) "Install AS3 Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

sleep 10

# Check DO Ready
CNT=0
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/declarative-onboarding | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! Declarative Onboarding is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  DO Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

# Check CF Ready
CNT=0
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/cloud-failover/declare | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! Cloud Failover is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  CF Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

# Check AS3 Ready
CNT=0
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/appsvcs/info | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! AS3 is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  AS3 Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

# Check TS Ready
CNT=0
while true
do
  STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/telemetry/declare | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! TS is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  TS Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

sleep 60