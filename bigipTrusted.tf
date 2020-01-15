# https://github.com/F5Networks/f5-aws-cloudformation/tree/master/supported/failover/across-net/via-api/3nic/existing-stack/byol/
resource "aws_cloudformation_stack" "bigipTrusted" {
	name = "cf${var.tag_name}-Trusted"
	template_url = "${var.bigip_cft}"
	parameters = {
		Vpc = "${aws_vpc.main.id}"
		ntpServer = "${var.ntp_server}"
		bigIpModules = "${var.trusted_f5provisioning}"
		provisionPublicIP = "No"
		#declarationUrl = ""
		managementSubnetAz1 = "${aws_subnet.mgmt1.id}"
		managementSubnetAz2 = "${aws_subnet.mgmt2.id}"
		subnet1Az1 = "${aws_subnet.dmzInt1.id}"
		subnet1Az2 = "${aws_subnet.dmzInt2.id}"
		subnet2Az1 = "${aws_subnet.trustedInt1.id}"
		subnet2Az2 = "${aws_subnet.trustedInt2.id}"
		imageName = "AllTwoBootLocations"
		instanceType = "m5.xlarge"
		licenseKey1 = "${var.bigip_lic3}"
		licenseKey2 = "${var.bigip_lic4}"
		sshKey = "${aws_key_pair.main.id}"
		restrictedSrcAddress = "${var.mgmt_asrc[0]}"
		restrictedSrcAddressApp = "0.0.0.0/0"
		timezone = "UTC"
		allowUsageAnalytics = "No"
	}
	capabilities = ["CAPABILITY_IAM"]
}