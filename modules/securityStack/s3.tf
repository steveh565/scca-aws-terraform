# F5 Cloud-Failover extension: S3 storage buckets

# Create a bucket
resource "aws_s3_bucket" "cfPaz" {
  bucket        = lower("${var.prefix}-PAZ-CF-storage")
  acl           = "private"
  force_destroy = true

  tags = {
    name = "${var.prefix}-PAZ-CF-storage"
    f5_cloud_failover_label = var.paz_cf_label
  }
}


# Create a bucket
resource "aws_s3_bucket" "cfDmz" {
  bucket        = lower("${var.prefix}-DMZ-CF-storage")
  acl           = "private"
  force_destroy = true

  tags = {
    name = "${var.prefix}-DMZ-CF-storage"
    f5_cloud_failover_label = var.dmz_cf_label
  }
}


# Create a bucket
resource "aws_s3_bucket" "cfTransit" {
  bucket        = lower("${var.prefix}-Transit-CF-storage")
  acl           = "private"
  force_destroy = true

  tags = {
    name = "${var.prefix}-Transit-CF-storage"
    f5_cloud_failover_label = var.transit_cf_label
  }
}