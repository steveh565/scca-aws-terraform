resource "aws_cloudwatch_log_group" "f5telemetry" {
  name = "${var.prefix}-${var.cwLogGroup}"
  tags = {
      ResourceGroup = "${var.prefix}"
  }
}

resource "aws_cloudwatch_log_stream" "pazF5vm01" {
  depends_on = [aws_cloudwatch_log_group.f5telemetry]
  name           = "${var.prefix}-${var.az1_pazF5.hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "pazF5vm02" {
  depends_on = [aws_cloudwatch_log_group.f5telemetry]
  name           = "${var.prefix}-${var.az2_pazF5.hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "dmzF5vm01" {
  depends_on = [aws_cloudwatch_log_group.f5telemetry]
  name           = "${var.prefix}-${var.az1_dmzF5.hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "dmzF5vm02" {
  depends_on = [aws_cloudwatch_log_group.f5telemetry]
  name           = "${var.prefix}-${var.az2_dmzF5.hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "transitF5vm01" {
  depends_on = [aws_cloudwatch_log_group.f5telemetry]
  name           = "${var.prefix}-${var.az1_transitF5.hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}

resource "aws_cloudwatch_log_stream" "transitF5vm02" {
  depends_on = [aws_cloudwatch_log_group.f5telemetry]
  name           = "${var.prefix}-${var.az2_transitF5.hostname}"
  log_group_name = "${var.prefix}-${var.cwLogGroup}"
}