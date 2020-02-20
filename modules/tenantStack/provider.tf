provider "aws" {
	region = "${var.aws_region}"
    #uncomment if you set these variables in vars.tf
	#Comment out if you wish to use ENV variables for auth tokens
	#access_key = var.SP.access_key
	#secret_key = var.SP.secret_key
}