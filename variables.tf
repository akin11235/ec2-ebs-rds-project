variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "user1-create-EC2"
}


# terraform plan -var="aws_profile=user1-create-EC2"
# ssh -i ~/.ssh/tf_keys/ec2_tf_training_key.pem ec2-user@<EC2_PUBLIC_IP>
