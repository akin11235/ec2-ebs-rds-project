terraform {
  backend "s3" {
    bucket         = "iac-ec2-ebs-rds-bucket" # S3 bucket name
    key            = "terraform.tfstate"      # Path to store state file
    region         = "us-east-1"              # S3 bucket region
    dynamodb_table = "iac-ec2-ebs-rds"        # Optional - for state locking
    encrypt        = true                     # Encrypt state at rest
  }
}
