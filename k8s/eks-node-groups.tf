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

# Node groups
resource "aws_eks_node_group" "ek8s" {
  cluster_name    = aws_eks_cluster.ek8s.name
  node_group_name = local.eks_node_group
  node_role_arn   = aws_iam_role.ek8s_node_group.arn
  subnet_ids      = module.vpc.private_subnets

  # ubuntu ami types -> https://cloud-images.ubuntu.com/aws-eks/
  ami_type = "BOTTLEROCKET_x86_64"
  # t2.micro - free tier
  # instance_types = ["t2.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 10
    min_size     = 2
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
