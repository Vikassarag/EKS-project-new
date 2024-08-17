#We create a role using the module iam-role-for-service-accounts-eks which will create the required policy when attach_load_balancer_controller_policy is set to true.
module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "dev_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = "arn:aws:iam::370571693924:oidc-provider/oidc.eks.ap-south-1.amazonaws.com/id/71872CB84A347BB9A7D58AB8E161BF75"
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

#2. We create a service account that is annotated with the role created in the above step.
resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = "arn:aws:iam::370571693924:role/dev_eks_lb"
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

#3. Finally, we install the AWS load balancer controller.
resource "helm_release" "alb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service-account
  ]

  set {
    name  = "region"
    value = "ap-south-1"
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.ap-south-1.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks_cluster.name
  }
}