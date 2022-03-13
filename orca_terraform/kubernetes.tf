provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}

resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres"
    namespace = "default"
  }

  data = {
    connectionstring = "postgresql://${module.db.db_instance_username}:${module.db.db_instance_password}@${module.db.db_instance_address}/${module.db.db_instance_name}"
  }
  type = "Opaque"
}