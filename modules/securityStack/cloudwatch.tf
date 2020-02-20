resource "aws_cloudwatch_log_group" "f5telemetry" {
  name = "${var.prefix}-${var.cwLogGroup}"
  tags = {
      ResourceGroup = "${var.prefix}"
  }
}

resource "aws_cloudwatch_log_stream" "pazF5vm01" {
  name           = "${var.prefix}-${var.paz_az1_hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "pazF5vm02" {
  name           = "${var.prefix}-${var.paz_az2_hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "dmzF5vm01" {
  name           = "${var.prefix}-${var.dmz_az1_hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "dmzF5vm02" {
  name           = "${var.prefix}-${var.dmz_az2_hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "transitF5vm01" {
  name           = "${var.prefix}-${var.transit_az1_hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "transitF5vm02" {
  name           = "${var.prefix}-${var.transit_az2_hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}