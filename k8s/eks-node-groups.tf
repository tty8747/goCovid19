# IAM Role for EKS node group
resource "aws_iam_role" "ek8s_node_group" {
  name = local.eks_node_group

  assume_role_policy = jsonencode(
    {
      Statement = [{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }]
      Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "ek8s-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.ek8s_node_group.name
}

resource "aws_iam_role_policy_attachment" "ek8s-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.ek8s_node_group.name
}

resource "aws_iam_role_policy_attachment" "ek8s-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ek8s_node_group.name
}

# https://github.com/aws-observability/aws-otel-helm-charts/tree/main/charts/adot-exporter-for-eks-on-ec2#prerequisites
resource "aws_iam_role_policy_attachment" "ek8s-CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.ek8s_node_group.name
}

# if Amazon Managed Service for Prometheus will be used
resource "aws_iam_role_policy_attachment" "ek8s-AmazonPrometheusRemoteWriteAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
  role       = aws_iam_role.ek8s_node_group.name
}


# Node groups
resource "aws_eks_node_group" "ek8s-api" {
  cluster_name    = aws_eks_cluster.ek8s.name
  node_group_name = "${local.eks_node_group}-api"
  node_role_arn   = aws_iam_role.ek8s_node_group.arn
  subnet_ids      = module.vpc.private_subnets
  labels = {
    aim = "api"
  }

  # ubuntu ami types -> https://cloud-images.ubuntu.com/aws-eks/
  # ami_type = "BOTTLEROCKET_x86_64"
  # t2.micro - free tier
  # instance_types = ["t2.micro"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 10
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.ek8s-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.ek8s-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.ek8s-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"               = "TRUE"
  }
}

resource "aws_eks_node_group" "ek8s-front" {
  cluster_name    = aws_eks_cluster.ek8s.name
  node_group_name = "${local.eks_node_group}-front"
  node_role_arn   = aws_iam_role.ek8s_node_group.arn
  subnet_ids      = module.vpc.public_subnets
  labels = {
    aim = "front"
  }

  # ubuntu ami types -> https://cloud-images.ubuntu.com/aws-eks/
  # ami_type = "BOTTLEROCKET_x86_64"
  # t2.micro - free tier
  # instance_types = ["t2.micro"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 10
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.ek8s-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.ek8s-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.ek8s-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"               = "TRUE"
  }
}

# resource "aws_eks_node_group" "ek8s2-build" {
#   cluster_name    = aws_eks_cluster.ek8s.name
#   node_group_name = "${local.eks_node_group}-build"
#   node_role_arn   = aws_iam_role.ek8s_node_group.arn
#   subnet_ids      = module.vpc.private_subnets
# 
#   # ubuntu ami types -> https://cloud-images.ubuntu.com/aws-eks/
#   # t2.micro - free tier
#   instance_types = ["t2.micro"]
# 
#   scaling_config {
#     desired_size = 1
#     min_size     = 1
#     max_size     = 10
#   }
# 
#   update_config {
#     max_unavailable = 1
#   }
# 
#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#   depends_on = [
#     aws_iam_role_policy_attachment.ek8s-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.ek8s-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.ek8s-AmazonEC2ContainerRegistryReadOnly,
#   ]
# 
#   tags = {
#     "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
#     "k8s.io/cluster-autoscaler/enabled"               = "TRUE"
#   }
# }
