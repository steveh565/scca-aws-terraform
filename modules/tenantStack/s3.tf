# F5 Cloud-Failover extension: S3 storage buckets

# Create a bucket
resource "aws_s3_bucket" "cfTenant" {
  bucket        = lower("${var.prefix}-${var.tenant_name}-CF-storage")
  acl           = "private"
  force_destroy = true

  tags = {
    name = "${var.prefix}-${var.tenant_name}-CF-storage"
    f5_cloud_failover_label = var.tenant_cf_label
  }
}