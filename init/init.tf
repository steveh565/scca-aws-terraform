# Infrastructure
provider "aws" {
	region = "${var.aws_region}"
  
  #uncomment if you set these variables in vars.tf
	#Comment out if you wish to use ENV variables for auth tokens
	access_key = var.SP.access_key
	secret_key = var.SP.secret_key
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = lower("${var.tag_name}-${var.tfstate_s3Bucket}")
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
  name         = lower("${var.tag_name}-${var.tfstate_dynamoLocksDb}")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" { 
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table"
}