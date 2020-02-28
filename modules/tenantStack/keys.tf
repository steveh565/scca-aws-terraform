# EC2 key pair
resource "aws_key_pair" "tenant" {
	key_name = "kp${var.tenant_name}"
	public_key = file(var.key_path)
}