# EC2 key pair
resource "aws_key_pair" "maz" {
	key_name = "kp${var.maz_name}"
	public_key = file(var.key_path)
}

# AMI
data "aws_ami" "ubuntu" {
	most_recent = true
	filter {
		name = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
	}
	filter {
		name = "virtualization-type"
		values = ["hvm"]
	}
	owners = ["099720109477"] #Canonical
}

# Instance
resource "aws_instance" "az1_bastionHost" {
	depends_on = [aws_subnet.az1_maz_int]
	ami = data.aws_ami.ubuntu.id
	instance_type = "t2.micro"
	key_name = aws_key_pair.maz.id
	subnet_id = aws_subnet.az1_maz_int.id
	vpc_security_group_ids = [aws_security_group.maz_sg_internal.id]
	associate_public_ip_address = true
	source_dest_check = false
	# user_data = file("install.sh")
	user_data = <<-EOF
		# Core dependencies
		sudo apt-get update
		curl -fsSL https://get.docker.com | sh
		sudo usermod -aG docker $USER
		newgrp docker
		#
		# Bastion Host
		echo "${var.uname}:${var.upassword}:Y" > /root/createusers.txt
		docker run --restart unless-stopped -p 2222:22 -p 3389:3389 -v /root/createusers.txt -v /home -dit rattydave/docker-ubuntu-xrdp-mate-custom:19.10
	EOF

	tags = {
		Name = "az1_BastionHost${count.index}"
		f5sd = "pool_BastionHost"
		f5rg = var.tag_name
		tenant = var.maz_name
	}
	count = 1
}

resource "aws_instance" "az2_bastionHost" {
	depends_on = [aws_subnet.az2_maz_int]
	ami = data.aws_ami.ubuntu.id
	instance_type = "t2.micro"
	key_name = aws_key_pair.maz.id
	subnet_id = aws_subnet.az2_maz_int.id
	vpc_security_group_ids = [aws_security_group.maz_sg_internal.id]
	associate_public_ip_address = true
	source_dest_check = false
	# user_data = file("install.sh")
	user_data = <<-EOF
		# Core dependencies
		sudo apt-get update
		curl -fsSL https://get.docker.com | sh
		sudo usermod -aG docker $USER
		newgrp docker
		#
		# Bastion Host
		echo "${var.uname}:${var.upassword}:Y" > /root/createusers.txt
		docker run --restart unless-stopped -p 2222:22 -p 3389:3389 -v /root/createusers.txt -v /home -dit rattydave/docker-ubuntu-xrdp-mate-custom:19.10
	EOF

	tags = {
		Name = "az2_BastionHost${count.index}"
		f5sd = "pool_BastionHost"
		f5rg = var.tag_name
		tenant = var.maz_name
	}
	count = 1
}

# Setup Onboarding scripts
data "template_file" "az1_mazF5_vm_onboard" {
  template = file("${path.root}/onboard.tpl")

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL		     = var.AS3_URL
    TS_URL		     = var.TS_URL
    CF_URL		     = var.CF_URL
    libs_dir	     = var.libs_dir
    onboard_log	   = var.onboard_log

    mgmt_ip        = var.az1_mazF5.mgmt
    mgmt_gw        = local.az1_mgmt_gw
    vpc_dns        = local.maz_vpc_dns
    ext_self       = var.az1_mazF5.maz_ext_self
    int_self       = var.az1_mazF5.maz_int_self
    gateway        = local.az1_maz_ext_gw
  }
}

# Render Onboarding script
resource "local_file" "az1_mazF5_vm_onboarding_file" {
  content     = data.template_file.az1_mazF5_vm_onboard.rendered
  filename    = "${path.module}/${var.az1_mazF5_onboard_script}"
}


data "template_file" "az2_mazF5_vm_onboard" {
  template = file("${path.root}/onboard.tpl")

  vars = {
    uname          = var.uname
    upassword      = var.upassword
    DO_onboard_URL = var.DO_onboard_URL
    AS3_URL		     = var.AS3_URL
    TS_URL		     = var.TS_URL
    CF_URL		     = var.CF_URL
    libs_dir	     = var.libs_dir
    onboard_log	   = var.onboard_log

    mgmt_ip        = var.az2_mazF5.mgmt
    mgmt_gw        = local.az2_mgmt_gw
    vpc_dns        = local.maz_vpc_dns    
    ext_self       = var.az2_mazF5.maz_ext_self
    int_self       = var.az2_mazF5.maz_int_self
    gateway        = local.az2_maz_ext_gw
  }
}

# Render Onboarding script
resource "local_file" "az2_mazF5_vm_onboarding_file" {
  content     = data.template_file.az2_mazF5_vm_onboard.rendered
  filename    = "${path.module}/${var.az2_mazF5_onboard_script}"
}

locals {
    depends_on   = []
    az1_mgmt_gw  = cidrhost(var.az1_maz_subnets.mgmt, 1)
    az2_mgmt_gw  = cidrhost(var.az2_maz_subnets.mgmt, 1)

    az1_maz_ext_gw   = cidrhost(var.az1_maz_subnets.transit, 1)
    az2_maz_ext_gw   = cidrhost(var.az2_maz_subnets.transit, 1)
    az1_maz_int_gw   = cidrhost(var.az1_maz_subnets.internal, 1)
    az2_maz_int_gw   = cidrhost(var.az2_maz_subnets.internal, 1)

	maz_vpc_dns          = cidrhost(var.maz_vpc_cidr, 2)
}

module "storage-maz" {
#  source = "./modules/storage"
  source = "../storage"  
  storage_label = var.maz_cf_label
}

/*
module "f5SraWebPortal" { 
  source = "../f5SraWebPortal"
  bigip_mgmt_public_ip = aws_instance.az1_maz_bigip.public_ip
  bigip_vip_private_ip = var.tenant_values.maz.az1.ext_vip
  tenant_values = var.tenant_values
  uname = var.uname
  upassword  = var.upassword
}
*/
