# fetch the appropriate AMI ID for BIGIP (will provide the appropriate AMI ID, which varies by AWS region)
data "aws_ami" "bigip_ami" {
  most_recent = true
  owners = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["F5 BIGIP-15*BYOL-All*2Boot*"]
  }
}