data "aws_availability_zones" "available" {
}


data "aws_key_pair" "ec2_key" {
  key_name = "ec2_key"
}

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

}