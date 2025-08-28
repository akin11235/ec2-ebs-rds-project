# This is a new main.tf for create an ec2 instance. attach additional ebs volume of type gp3 with 20gb of storage. install any pre-spftware and take a backup. the ec2 instace should have access to rds.

# =============================================================================
# TERRAFORM CONFIGURATION AND PROVIDER SETUP
# =============================================================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.10"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Default provider
provider "aws" {
  region  = "us-east-1"
  profile = "user1-create-EC2"
}

provider "aws" {
  region = "us-east-1"   # <-- use the same region where your EC2 lives
  profile = "user1-create-EC2"
  alias   = "user1"
}

# =============================================================================
# DATA SOURCES
# Query existing AWS resources and information
# =============================================================================

# Get list of available availability zones in the current region
data "aws_availability_zones" "available" {
  state = "available" # Only get AZs that are currently available
  # This ensures we don't try to create resources in unavailable AZs
}


# =============================================================================
# NETWORKING INFRASTRUCTURE
# Create VPC, subnets, gateways, and routing
# =============================================================================

# Virtual Private Cloud - Creates isolated network environment
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"

  # Enable DNS resolution and hostnames for internal communication
  enable_dns_hostnames = true # Allows instances to get public DNS names
  enable_dns_support   = true # Enables DNS resolution via Amazon DNS server

  tags = {
    Name = "MainProject-VPC"
  }
  # VPC acts as the container for all our network resources
}


# Internet Gateway - Provides internet access to public subnets
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id # Attach to our VPC

  tags = {
    Name = "MainProject-IGW"
  }
   # IGW is managed by AWS, horizontally scaled, redundant, and highly available
}

# Public Subnet - Resources here can have direct internet access
resource "aws_subnet" "public_sn1_tfproject" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0] # Use first available AZ
  map_public_ip_on_launch = true # Automatically assign public IPs to instances

  tags = {
    Name = "public_sn1_tfproject"
    Type = "Public"
  }
  # Public subnet is where the EC2 instance will reside.
}


# Private Subnet - No direct internet access, first AZ
resource "aws_subnet" "private_sn1_tfproject" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]  # Same AZ as public

  tags = {
    Name = "private_sn1_tfproject"
    Type = "Private"
  }
   # This subnet will host the RDS database subnet group
}

# Private Subnet - Second AZ
resource "aws_subnet" "private_sn2_tfproject" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]  # Second AZ

  tags = {
    Name = "private_sn2_tfproject"
    Type = "Private"
  }
}



# =============================================================================
# ROUTING CONFIGURATION
# Control how network traffic flows between subnets and the internet
# =============================================================================

# Public Route Table - Routes traffic from public subnet to internet
resource "aws_route_table" "public-route-table-1" {
  vpc_id = aws_vpc.main_vpc.id

# Default route: send all traffic (0.0.0.0/0) to Internet Gateway
  route {
    cidr_block = "0.0.0.0/0" # All destinations
    gateway_id = aws_internet_gateway.main_igw.id
  }
 # This enables bidirectional internet connectivity for public subnet

  tags = {
    Name = "Public-Route-Table-1"
  }
}

# Private Route Table - No direct internet access
resource "aws_route_table" "private-route-table-1" {
  vpc_id = aws_vpc.main_vpc.id

  # No routes to Internet Gateway
  # Private subnets can only communicate within VPC by default
  # To add internet access, you would add a route to NAT Gateway
  tags = {
    Name = "Private-Route-Table-1"
  }
}


# =============================================================================
# ROUTE TABLE ASSOCIATIONS
# Link subnets to their respective route tables
# =============================================================================

# Associate public subnet with public route table
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_sn1_tfproject.id
  route_table_id = aws_route_table.public-route-table-1.id
  # This gives the public subnet internet access via IGW
}

# Associate private subnet A with private route table
resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_sn1_tfproject.id
  route_table_id = aws_route_table.private-route-table-1.id
  # Private subnet A has no internet access - secure for databases
}

# =============================================================================
# SECURITY GROUPS
# Virtual firewalls that control traffic to/from resources
# =============================================================================

# Security Group to control access to EC2 instance
resource "aws_security_group" "ec2_web" {
  name_prefix = "ec2-sg" # AWS will append random string to ensure uniqueness
  vpc_id      = aws_vpc.main_vpc.id


# INBOUND RULES (Ingress)
  # Allow HTTP traffic from anywhere on the internet
  ingress {
    from_port   = 80  # HTTP port
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from any IP address
  }

# Allow HTTPS traffic from anywhere on the internet
  ingress {
    from_port   = 443  # HTTPS port
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 # Allow SSH access for server administration
  ingress {
    from_port   = 22  # SSH port
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In production, restrict to specific IPs
  }


  # OUTBOUND RULES (Egress)
  # Allow all outbound traffic (needed for package downloads, API calls, etc.)
  egress {
    from_port   = 0   # All ports
    to_port     = 0
    protocol    = "-1"   # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # To any destination
  }

  tags = {
    Name = "EC2-SG"
  }
}


# Security Group for Database - Highly restrictive
resource "aws_security_group" "database" {
  name_prefix = "database-sg"
  vpc_id      = aws_vpc.main_vpc.id

# INBOUND RULES (Ingress)
  # Only allow PostgreSQL traffic from web server security group
  ingress {
    from_port       = 5432  # PostgreSQL default port
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_web.id] # Only from web server SG
    # This creates a security group rule that references another security group
    # More secure than IP-based rules as it automatically adapts to instance changes
  }

# OUTBOUND RULES (Egress)
  # Allow outbound traffic for updates and patches
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database-SG"
  }
  # Database can only receive connections from web servers, not directly from internet
}


# =============================================================================
# COMPUTE RESOURCES
# EC2 instances and related infrastructure
# =============================================================================

# SSH Key Pair for accessing EC2 instances
# Generate a new TLS private Key for SSH
resource "tls_private_key" "ec2_tf_training_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "ec2_tf_training_key_pair" {
  provider   = aws.user1
  key_name   = "ec2-tf-training-key"  # AWS key name
  public_key = tls_private_key.ec2_tf_training_key.public_key_openssh
}

# Output the key for use in SSH
output "private_key_pem" {
  value     = tls_private_key.ec2_tf_training_key.private_key_pem
  sensitive = true
}

# Output the key name for reference
output "key_pair_name" {
  value = aws_key_pair.ec2_tf_training_key_pair.key_name
}


# EC2 using the key pair
resource "aws_instance" "training_server" {
  provider      = aws.user1
  ami           = "ami-00ca32bbc84273381"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.ec2_tf_training_key_pair.key_name

  # User Data: Install software & prepare EBS
  user_data = <<-EOF
              #!/bin/bash
              # Update system and install packages
              yum update -y
              yum install -y httpd # add any pre-installed software you want

              # Wait for attached EBS volume
              while [ ! -e /dev/nvme1n1 ]; do sleep 1; done
              mkfs -t ext4 /dev/nvme1n1
              mkdir -p /mnt/extra
              mount /dev/nvme1n1 /mnt/extra
              echo '/dev/nvme1n1 /mnt/extra ext4 defaults,nofail 0 2' >> /etc/fstab
              EOF

  tags = {
    Name        = "Training-Server"
    Environment = "Prod"
    Owner       = "Operations"
    Project     = "DevOps Launchpad"
  }
}

# ----------------------------
# EBS Volume
# ----------------------------
resource "aws_ebs_volume" "extra_volume" {
  availability_zone = aws_instance.training_server.availability_zone
  size              = 20
  type              = "gp3"
  tags = {
    Name = "Training-Extra-Volume"
  }
}

resource "aws_volume_attachment" "extra_volume_attach" {
  device_name  = "/dev/sdf"
  instance_id  = aws_instance.training_server.id
  volume_id    = aws_ebs_volume.extra_volume.id
  force_detach = true
}

# ----------------------------
# Create Backup AMI after Instance Launch
# ----------------------------
resource "aws_ami_from_instance" "training_server_backup" {
  name               = "training-server-backup-${timestamp()}"
  source_instance_id = aws_instance.training_server.id
  snapshot_without_reboot = true   # Avoids rebooting the instance
  tags = {
    Name = "Training-Server-Backup"
  }
}


# =============================================================================
# DATABASE RESOURCES
# RDS PostgreSQL instance and related infrastructure
# =============================================================================

# Subnet group for rds
resource "aws_db_subnet_group" "private_sn1_tfproject" {
  name        = "private-sn1-tfproject"
  description = "Subnet group for RDS instance"

  # Reference the private subnet
  subnet_ids = [
    aws_subnet.private_sn1_tfproject.id,
    aws_subnet.private_sn2_tfproject.id
  ]

  tags = {
    Name = "private-sn1-tfproject"
  }
}



# ----------------------------
# PostgreSQL RDS Database Instance (Minimal)
# ----------------------------
resource "aws_db_instance" "postgres" {
  # Basic configuration
  identifier        = "webapp-postgres"    # Unique DB identifier
  allocated_storage = 20                   # Storage in GB
  storage_type      = "gp2"                # General Purpose SSD
  engine            = "postgres"           # Database engine
  engine_version    = "14.18"             # PostgreSQL version
  instance_class    = "db.t3.micro"        # Small, free-tier eligible

  # Database credentials
  db_name  = "webapp"                      # Initial DB name
  username = "webadmin"                     # Master username
  password = "ChangeMe123!"                # Master password (use Secrets Manager in production)

  # Networking
  vpc_security_group_ids = [aws_security_group.database.id]  # Security group
  db_subnet_group_name   = aws_db_subnet_group.private_sn1_tfproject.name     # Subnet group

  # Development safety settings
  skip_final_snapshot = true               # Allows quick destroy in dev
  deletion_protection = false              # Allows Terraform destroy

  # Tags
  tags = {
    Name = "WebApp-PostgreSQL"
  }

  # Notes:
  # - AWS manages:
  #   * OS and DB patching
  #   * Automated backups
  #   * Multi-AZ failover (if enabled)
  #   * Monitoring (CloudWatch)
}
