/*
Steve is replacing CFT's with AWS Terraform modules!
# https://github.com/F5Networks/f5-aws-cloudformation/tree/master/supported/failover/across-net/via-api/3nic/existing-stack/byol/
resource "aws_cloudformation_stack" "bigipMAZ" {
	name = "cf${var.tag_name}-${var.maz_name}"
	template_url = "${var.bigip_cft}"
	parameters = {
		Vpc = "${aws_vpc.maz.id}"
		ntpServer = "${var.ntp_server}"
		bigIpModules = "${var.maz_f5provisioning}"
		provisionPublicIP = "Yes"
		#declarationUrl = ""
		managementSubnetAz1 = "${aws_subnet.maz_mgmt1.id}"
		managementSubnetAz2 = "${aws_subnet.maz_mgmt2.id}"
		subnet1Az1 = "${aws_subnet.maz_ext1.id}"
		subnet1Az2 = "${aws_subnet.maz_ext2.id}"
		subnet2Az1 = "${aws_subnet.maz_int1.id}"
		subnet2Az2 = "${aws_subnet.maz_int2.id}"
		imageName = "AllTwoBootLocations"
		instanceType = "m5.xlarge"
		licenseKey1 = "${var.maz_bigip_lic1}"
		licenseKey2 = "${var.maz_bigip_lic2}"
		sshKey = "${aws_key_pair.maz.id}"
		restrictedSrcAddress = "${var.mgmt_asrc[0]}"
		restrictedSrcAddressApp = "0.0.0.0/0"
		timezone = "UTC"
		allowUsageAnalytics = "No"
	}
	capabilities = ["CAPABILITY_IAM"]
}
*/
