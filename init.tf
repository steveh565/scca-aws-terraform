# Infrastructure
provider "aws" {
	region = "${var.aws_region}"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.tag_name}-${var.tfstate_s3Bucket}"
  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.tag_name}-${var.tfstate_dynamoLocksDb}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

#terraform {
#  backend "s3" {
#    # Replace this with your bucket name!
#    bucket         = "SHSCCA5-tfSharedState"
#    key            = "global/s3/terraform.tfstate"
#    region         = "ca-central-1"
#    # Replace this with your DynamoDB table name!
#    dynamodb_table = "SHSCCA5-tfLocks"
#    encrypt        = true
#  }
#}