provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.main.token
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    token                  = data.aws_eks_cluster_auth.main.token
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  }
}

data "aws_eks_cluster_auth" "main" {
 name = aws_eks_cluster.eks_cluster.name
}

# resource "helm_release" "argocd" {
#   name       = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   version    = "5.19.12"  # Use the latest version or specify as needed
#   namespace = "argocd"
#   create_namespace = true
#   set {
#     name  = "server.service.type"
#     value = "LoadBalancer"
#   }

# #   set {
# #     name  = "server.extraArgs"
# #     value = "--insecure"
# #   }

#   # Add other configurations as needed
# }



# data "kubernetes_service" "argocd_server" {
#  metadata {
#    name      = "argocd-server"
#    namespace = helm_release.argocd.namespace
#  }
# }