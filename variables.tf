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



# =============================================================================
# SECURITY GROUPS
# Virtual firewalls that control traffic to/from resources
# =============================================================================

# # Egress rules
# =============================================================================
variable "egress_protocol" {
  description = "All protocols"
  type        = string
  # default     = "-1"
}

variable "egress_cidr_blocks" {
  description = "CIDR block representing open access (0.0.0.0/0)"
  type        = list(string)
  # default     = ["0.0.0.0/0"]
}

variable "egress_to_port" {
  description = "Egress rule ending port"
  type        = number
  # default     = 0

}

variable "egress_from_port" {
  description = "Egress rule starting port"
  type        = number
  # default     = 0

}


# # Ingress rules
# =============================================================================
variable "ingress_protocol" {
  description = "Protocol for ingress rule"
  type        = string
}

# Allow from any IP address
variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed for ingress"
  type        = list(string)
}

# variable "ingress_to_port" {
# description = "Ingress rule ending port"
#   type        = number
#   default     = 8080
# }

# variable "ingress_from_port"{
#   description = "Ingress rule starting port"
#   type        = number
#   default     = 8080

# }



# HTTP rules
variable "http_to_port" {
  description = "Port for HTTP traffic"
  type        = number
}

variable "http_from_port" {
  description = "Port for HTTP traffic"
  type        = number
}


variable "https_to_port" {
  description = "Port for HTTPS traffic"
  type        = number
}

variable "https_from_port" {
  description = "Port for HTTPS traffic"
  type        = number
}
# ssh rules
variable "ssh_to_port" {
  description = "Port for SSH access"
  type        = number
}

variable "ssh_from_port" {
  description = "Port for SSH access"
  type        = number
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # In prod, restrict to specific IPs
}

variable "https_allowed_cidrs" {
  description = "CIDR blocks allowed for HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Variable for port 8080
variable "app_port" {
  description = "Port for application traffic (e.g., HTTP alternative)"
  type        = number
  default     = 8080
}

variable "app_allowed_cidrs" {
  description = "CIDR blocks allowed for application traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change in production
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

# =============================================================================
# COMPUTE RESOURCES
# EC2 instances and related infrastructure
# =============================================================================
# ami_id          = "ami-0861f4e788f5069dd"   # Example AMI for us-east-1

variable "instance_name" {
  description = "Tag name for the instance"
  type        = string
  default     = "Ubuntu-Web-Server"

}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}








# terraform plan -var="aws_profile=user1-create-EC2"
# ssh -i ~/.ssh/tf_keys/ec2_tf_training_key.pem ec2-user@<EC2_PUBLIC_IP>
