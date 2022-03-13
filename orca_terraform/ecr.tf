resource "aws_ecr_repository" "ecr-registry" {
  name                 = "orca-task"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.eks.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}