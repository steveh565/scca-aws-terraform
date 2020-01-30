resource "aws_iam_role" "bigip-Failover-Extension-IAM-role" {
  name = "bigip-Failover-Extension-IAM-role"

  assume_role_policy = file("${path.module}/bigip-Failover-Extension-IAM-role-Assume-Role.json")

  tags = {
    name = "f5_cloud_failover_iam_role"
  }
}

resource "aws_iam_policy" "bigip-Failover-Extension-IAM-policy" {
  name        = "bigip-Failover-Extension-IAM-policy"
  description = "for bigip cloud failover extension"
  policy      = file("bigip-Failover-Extension-IAM-policy.json")
}

resource "aws_iam_policy_attachment" "bigip-Failover-Extension-IAM-policy-attach" {
  depends_on = [aws_iam_policy.bigip-Failover-Extension-IAM-policy]
  name       = "bigip-Failover-Extension-IAM-policy-attach"
  roles      = [aws_iam_role.bigip-Failover-Extension-IAM-role.name]
  policy_arn = aws_iam_policy.bigip-Failover-Extension-IAM-policy.arn
}


resource "aws_iam_instance_profile" "bigip-Failover-Extension-IAM-instance-profile" {
  depends_on = [aws_iam_role.bigip-Failover-Extension-IAM-role]
  name = "bigip-Failover-Extension-IAM-instance-profile"
  role = aws_iam_role.bigip-Failover-Extension-IAM-role.name
}
