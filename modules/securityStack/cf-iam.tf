resource "aws_iam_role" "bigip-failover-extension-iam-role" {
  name = "${var.prefix}-GCCAP-bigip-failover-extension-iam-role"
  assume_role_policy = file("${path.module}/bigip-failover-extension-iam-role-assume-role.json")
  tags = {
    name = "${var.prefix}-GCCAP-f5_cloud_failover_iam_role"
  }
}

resource "aws_iam_policy" "bigip-failover-extension-iam-policy" {
  name        = "${var.prefix}-GCCAP-bigip-failover-extension-iam-policy"
  description = "for bigip cloud failover extension"
  policy      = file("${path.module}/bigip-failover-extension-iam-policy.json")
}

resource "aws_iam_policy_attachment" "bigip-failover-extension-iam-policy-attach" {
  depends_on = [aws_iam_policy.bigip-failover-extension-iam-policy]
  name       = "${var.prefix}-GCCAP-bigip-failover-extension-iam-policy-attach"
  roles      = [aws_iam_role.bigip-failover-extension-iam-role.name]
  policy_arn = aws_iam_policy.bigip-failover-extension-iam-policy.arn
}

resource "aws_iam_instance_profile" "bigip-failover-extension-iam-instance-profile" {
  depends_on = [aws_iam_role.bigip-failover-extension-iam-role]
  name = "${var.prefix}-GCCAP-bigip-failover-extension-iam-instance-profile"
  role = aws_iam_role.bigip-failover-extension-iam-role.name
}
