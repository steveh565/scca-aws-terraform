# Run REST API for configuration

# declare local vars
locals {
  depends_on = []
  mgmt_gw		 = "${cidrhost(aws_subnet.ext1.cidr_block, 1)}"
  ext_net    = "${var.ext1_cidr}"
}

variable bigipMgmtPublicIP { default = "1.2.3.4" }

resource "null_resource" "f5vm01_DO" {
  depends_on	= []
  # Running DO REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_do_method} https://${var.bigipMgmtPublicIP}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_f5vm01_do_file}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${var.bigipMgmtPublicIP}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 120
    EOF
  }
}

resource "null_resource" "f5vm01_TS" {
  depends_on    = []
  # Running CF REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -H 'Content-Type: application/json' -k -X POST https://${var.bigipMgmtPublicIP}${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_ts_file}
    EOF
  }
}

## Frontend Big-IP configuration
resource "null_resource" "bigip_AS3" {
  depends_on    = []
  # Running AS3 REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_as3_method} https://${var.bigipMgmtPublicIP}${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_as3_file}
    EOF
  }
}

resource "null_resource" "install_ano_rpms" {
    depends_on = []
    provisioner "local-exec" {
        command = <<-EOF
            #!/bin/bash
            LOG_FILE="${var.onboard_log}"

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
            STATUS=$(curl -s -k -I example.com | grep HTTP)
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

            sleep 60

            ### DOWNLOAD ONBOARDING PKGS
            admin_username="${var.uname}"
            admin_password="${var.upassword}"
            CREDS="admin:"$admin_password
            # Telemetry Streaming
            TS_URL="${var.TS_URL}"
            TS_FN=$(basename "$TS_URL")
            # Declarative Onboarding
            DO_URL="${var.DO_onboard_URL}"
            DO_FN=$(basename "$DO_URL")
            # Application Services
            AS3_URL="${var.AS3_URL}"
            AS3_FN=$(basename "$AS3_URL")
            # Cloud Failover
            CF_URL="${var.CF_URL}"
            CF_FN=$(basename "$CF_URL")

            mkdir -p "${var.libs_dir}"

            echo -e "\n"$(date) "Download TS Pkg"
            curl -L -o "${var.libs_dir}"/$TS_FN $TS_URL

            echo -e "\n"$(date) "Download Declarative Onboarding Pkg"
            curl -L -o "${var.libs_dir}"/$DO_FN $DO_URL

            echo -e "\n"$(date) "Download AS3 Pkg"
            curl -L -o "${var.libs_dir}"/$AS3_FN $AS3_URL

            echo -e "\n"$(date) "Download CF Pkg"
            curl -L -o "${var.libs_dir}"/$CF_FN $CF_URL
            # Copy the RPM Pkg to the file location
            cp "${var.libs_dir}"/*.rpm /var/config/rest/downloads/

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

            # Install AS3 Pkg
            DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$AS3_FN\"}"
            echo -e "\n"$(date) "Install AS3 Pkg"
            curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

            sleep 10

            # Install Cloud Failover Pkg
            DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$CF_FN\"}"
            echo -e "\n"$(date) "Install CF Pkg"
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

            # Check CF Ready
            CNT=0
            while true
            do
            STATUS=$(curl -u $CREDS -X GET -s -k -I https://localhost/mgmt/shared/cloud-failover/declare | grep HTTP)
            if [[ $STATUS == *"200"* ]]; then
                echo "Got 200! CF is Ready!"
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

        EOF
    }    
}



provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "tmsh revoke /sys license"
    ]
    on_failure = "continue"
  }
