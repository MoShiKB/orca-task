output "cluster_name" {
  value = local.cluster_name
}

output "cluster_id" {
  value = module.eks.cluster_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "region" {
  value = var.AWS_REGION
}

output "ecr_url" {
  value = aws_ecr_repository.ecr-registry.repository_url
}

