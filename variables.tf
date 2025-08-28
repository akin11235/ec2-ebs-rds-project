variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "user1-create-EC2"
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "open_cidr" {
  description = "CIDR block representing open access (0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}


variable "vpc_cidr" {
  description = "CIDR block for the entire VPC - defines IP address range"
  type        = string
  default     = "10.0.0.0/16"
  # This provides 65,536 IP addresses (10.0.0.0 to 10.0.255.255)
  # 10.x.x.x is a private IP range as defined in RFC 1918
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet - accessible from internet"
  type        = string
  default     = "10.0.1.0/24"
  # Provides 256 IP addresses (10.0.1.0 to 10.0.1.255)
  # Used for resources that need direct internet access (web servers)
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for first private subnet - no direct internet access"
  type        = string
  default     = "10.0.2.0/24"
  # Used for backend resources like databases
  # Can access internet through NAT Gateway if needed
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for second private subnet in different AZ"
  type        = string
  default     = "10.0.3.0/24"
  # Required by RDS for Multi-AZ deployment
  # Must be in different availability zone from private_subnet_a
}



# terraform plan -var="aws_profile=user1-create-EC2"
# ssh -i ~/.ssh/tf_keys/ec2_tf_training_key.pem ec2-user@<EC2_PUBLIC_IP>
