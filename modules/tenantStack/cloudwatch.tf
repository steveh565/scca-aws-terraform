resource "aws_cloudwatch_log_group" "f5telemetry" {
  name = "${var.prefix}-${local.cwLogGroupName}"
  tags = {
      ResourceGroup = "${var.prefix}"
  }
}

resource "aws_cloudwatch_log_stream" "az1F5vm01" {
  depends_on = [aws_cloudwatch_log_group.f5telemetry]
  name           = "${var.prefix}-${local.az1_cwLogStream}"
  log_group_name = "${var.prefix}-${local.cwLogGroupName}"
}

resource "aws_cloudwatch_log_stream" "az2F5vm02" {
  depends_on = [aws_cloudwatch_log_group.f5telemetry]
  name           = "${var.prefix}-${local.az2_cwLogStream}"
  log_group_name = "${var.prefix}-${local.cwLogGroupName}"
}
