#----------storage/main.tf-------

# Create a random id 
resource "random_id" "s3_storage_bucket" {
  byte_length = 2
}

# Create a bucket
resource "aws_s3_bucket" "cf" {
  bucket        = "${var.storage_label}-${random_id.s3_storage_bucket.dec}"
  acl           = "private"
  force_destroy = true

  tags = {
    f5_cloud_failover_label = var.storage_label
  }
}
