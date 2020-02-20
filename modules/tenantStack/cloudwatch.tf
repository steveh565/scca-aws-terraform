resource "aws_cloudwatch_log_group" "f5telemetry" {
  name = "${var.prefix}-${local.cwLogGroupName}"
  tags = {
      ResourceGroup = "${var.prefix}"
  }
}

resource "aws_cloudwatch_log_stream" "edgeF5vm01" {
  name           = "${var.prefix}-${local.az1_cwLogStream}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "edgeF5vm02" {
  name           = "${var.prefix}-${local.az2_cwLogStream}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}
