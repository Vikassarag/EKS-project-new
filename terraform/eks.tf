# Step 1: Security group for control plane Start
resource "aws_security_group" "control_plane_sg" {
  name   = "tf-sg-control_plane"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "Connectivity to EKS from tf-jumpbox"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["65.2.177.190/32"]
  }
  egress {
    description = "default outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-sg-control_plane"
  }
}
# Step 1: Security group for control plane End

# Step 2: EKS Cluster Start
resource "aws_iam_role" "cluster_role" {
  name               = "tf-role-cluster"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "tf-eks-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = "1.29"
  vpc_config {
    security_group_ids = [aws_security_group.control_plane_sg.id]
    subnet_ids = [
      aws_subnet.Blazeclan-MSteam1-private-1a.id,
      aws_subnet.Blazeclan-MSteam1-private-1b.id,
      aws_subnet.Blazeclan-MSteam1-public-1a.id,
      aws_subnet.Blazeclan-MSteam1-public-1b.id
    ]
    # endpoint_private_access = true
    # endpoint_public_access  = false
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]
}
# resource "aws_security_group_rule" "eks-cluster-sg-ingress-foscoll_preprod" {
#   type                     = "ingress"
#   from_port                = 22
#   to_port                  = 22
#   protocol                 = "tcp"
#   description              = "FOSCOLL Jump Server"
#   source_security_group_id = var.jumpbox_sgp_foscoll
#   security_group_id        = aws_eks_cluster.this_foscoll_preprod.vpc_config[0].cluster_security_group_id
# }

# Step 2: EKS Cluster end

resource "aws_security_group" "tf_sg_worker_eks" {
  name   = "tf_sg_worker_eks"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "Connectivity to EKS from jumpbox"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["65.2.177.190/32"]
  }
  egress {
    description = "default outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "node" {
  name               = "tf-role-eksworker"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}
# resource "aws_iam_role_policy_attachment" "node_CloudWatchAgentServerPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#   role       = aws_iam_role.node.name
# }
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_eks_node_group" "node-ms1" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "tf-node-ms1"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids = [
    aws_subnet.Blazeclan-MSteam1-private-1a.id,
    aws_subnet.Blazeclan-MSteam1-private-1b.id
  ]
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
  #ami_type       = "AL2_x86_64" # AL2_x86_64
  capacity_type  = "ON_DEMAND" # ON_DEMAND, SPOT
  instance_types = ["m5.xlarge"]
  remote_access {
    ec2_ssh_key               = data.aws_key_pair.Terraform.key_name
    source_security_group_ids = [aws_security_group.tf_sg_worker_eks.id]
  }
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

# data "tls_certificate" "eks" {
#   url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "eks" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
# }

#Step 3 of Worker Nodes End

# #Step 4 External Secret Role Start
# data "tls_certificate" "foscoll_preprod_tls_certificate" {
#   url = aws_eks_cluster.this_foscoll_preprod.identity[0].oidc[0].issuer
# }
# resource "aws_iam_openid_connect_provider" "foscoll_preprod_oidc" {
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.foscoll_preprod_tls_certificate.certificates[0].sha1_fingerprint]
#   url             = data.tls_certificate.foscoll_preprod_tls_certificate.url
# }
# resource "aws_iam_role" "foscoll-preprod-secret-irsa-role" {
#   name               = "tf-foscoll-secrets-preprod-irsa-role"
#   assume_role_policy = <<POLICY
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "Federated": "${aws_iam_openid_connect_provider.foscoll_preprod_oidc.arn}"
#             },
#             "Action": "sts:AssumeRoleWithWebIdentity",
#             "Condition": {
#                 "StringEquals": {
#                     "${aws_iam_openid_connect_provider.foscoll_preprod_oidc.url}:aud": "sts.amazonaws.com",
#                     "${aws_iam_openid_connect_provider.foscoll_preprod_oidc.url}:sub": "system:serviceaccount:preprod:external-secrets-irsa"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "Federated": "arn:aws:iam::157904387808:oidc-provider/oidc.eks.ap-south-1.amazonaws.com/id/702258D7A6AEFC1C950AAC0CAABED89C"
#             },
#             "Action": "sts:AssumeRoleWithWebIdentity",
#             "Condition": {
#                 "StringEquals": {
#                     "oidc.eks.ap-south-1.amazonaws.com/id/702258D7A6AEFC1C950AAC0CAABED89C:aud": "sts.amazonaws.com",
#                     "oidc.eks.ap-south-1.amazonaws.com/id/702258D7A6AEFC1C950AAC0CAABED89C:sub": "system:serviceaccount:preprod:external-secrets-irsa"
#                 }
#             }
#         }

#     ]
# }
# POLICY
# }
# resource "aws_iam_policy" "foscoll-preprod-secret-irsa-policy" {
#   name        = "tf-foscoll-secrets-preprod-irsa-policy"
#   description = "Secret Access for FOS Collection preprod"
#   path        = "/"
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "secretsmanager:DescribeSecret",
#           "secretsmanager:GetSecretValue"
#         ],
#         "Resource" : [
#           "arn:aws:secretsmanager:ap-south-1:157904387808:secret:/foscoll/preprod/*"
#         ]
#       }
#     ]
#   })
# }
# resource "aws_iam_role_policy_attachment" "foscoll-preprod-secret-irsa-rolePolicyAtt" {
#   role       = aws_iam_role.foscoll-preprod-secret-irsa-role.name
#   policy_arn = aws_iam_policy.foscoll-preprod-secret-irsa-policy.arn
# }
# #Step 4 External Secret Role End

# #Step 5 alb-controller-preprod-role Start
# resource "aws_iam_role" "tf_foscoll_alb_controller_preprod_role" {
#   name = "tf-foscoll-alb-controller-preprod-role"

#   assume_role_policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "Federated": "${aws_iam_openid_connect_provider.foscoll_preprod_oidc.arn}"
#             },
#             "Action": "sts:AssumeRoleWithWebIdentity",
#             "Condition": {
#                 "StringEquals": {
#                     "${aws_iam_openid_connect_provider.foscoll_preprod_oidc.url}:aud": "sts.amazonaws.com",
#                     "${aws_iam_openid_connect_provider.foscoll_preprod_oidc.url}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
#                 }
#             }
#         }
#     ]
# }
# EOF
# }

# # AWS managed policies
# resource "aws_iam_role_policy_attachment" "tf_foscoll_alb_controller_role_policy_attachment" {
#   role       = aws_iam_role.tf_foscoll_alb_controller_preprod_role.name
#   policy_arn = aws_iam_policy.tf_alb_controller_assume_policy.arn
# }
# #Step 5 alb-controller-preprod-role END
# #Step 6 eks-autoscaler-role Start

# resource "aws_iam_role" "tf-foscollpreprod-eks-autoscaler-role" {
#   name               = "tf-foscollpreprod-eks-autoscaler-role"
#   assume_role_policy = <<POLICY
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "Federated": "${aws_iam_openid_connect_provider.foscoll_preprod_oidc.arn}"
#             },
#             "Action": "sts:AssumeRoleWithWebIdentity",
#             "Condition": {
#                 "StringEquals": {
#                     "${aws_iam_openid_connect_provider.foscoll_preprod_oidc.url}:aud": "sts.amazonaws.com",
#                     "${aws_iam_openid_connect_provider.foscoll_preprod_oidc.url}:sub": ["system:serviceaccount:kube-system:cluster-autoscaler"]
#                 }
#             }
#         }
#     ]
# }
# POLICY
# }

# resource "aws_iam_policy" "tf_foscollpreprod_eks_autoscaler_assume_policy" {
#   name = "tf-foscollpreprod-eks_autoscaler-test-policy"
#   policy = jsonencode({
#     Statement = [
#       {
#         Action = [
#           "autoscaling:DescribeAutoScalingGroups",
#           "autoscaling:DescribeAutoScalingInstances",
#           "autoscaling:DescribeLaunchConfigurations",
#           "autoscaling:DescribeTags",
#           "autoscaling:SetDesiredCapacity",
#           "autoscaling:TerminateInstanceInAutoScalingGroup",
#           "ec2:DescribeLaunchTemplateVersions",
#           "ec2:*",
#           "autoscaling:*"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       }
#     ]
#     Version = "2012-10-17"
#   })
# }

# resource "aws_iam_role_policy_attachment" "tf_foscollpreprod_eks_autoscaler_policy_attachment" {
#   role       = aws_iam_role.tf-foscollpreprod-eks-autoscaler-role.name
#   policy_arn = aws_iam_policy.tf_foscollpreprod_eks_autoscaler_assume_policy.arn
# }
# #Step 6 eks-autoscaler-role End 