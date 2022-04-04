data "aws_eks_cluster_auth" "ek8s" {
  name = data.aws_eks_cluster.ek8s.name
}

data "aws_eks_cluster" "ek8s" {
  name = [for i in data.aws_eks_clusters.cluster_list.names : i if substr(i, 0, length(i)-3) == "eks-${var.k8s_name}"].0
  # name = [for i in data.aws_eks_clusters.cluster_list.names : i if substr("eks-dev-8q", 0, length("eks-dev-8q")-3) == "eks-dev"].0
}

data "aws_eks_clusters" "cluster_list" {}

data "aws_caller_identity" "current" {}

data "aws_iam_role" "AmazonEKSLoadBalancerControllerRole" {
  name = "${data.aws_eks_cluster.ek8s.name}-AmazonEKSLoadBalancerControllerRole"
}
