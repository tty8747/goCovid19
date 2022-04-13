# OpenID Connect provider
resource "aws_iam_openid_connect_provider" "default" {
  url             = aws_eks_cluster.ek8s.identity[0].oidc[0].issuer
  client_id_list  = var.openid_list
  thumbprint_list = [data.tls_certificate.ek8s.certificates[0].sha1_fingerprint]
}

# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/
# https://github.com/kubernetes-sigs/aws-load-balancer-controller

# IAM Role for EKS Load Balancer Controller add-on
# https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
resource "null_resource" "policy" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/usr/bin/env", "sh", "-c"]
    command     = <<EOT
            curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
     EOT
  }
}

resource "aws_iam_policy" "ek8s-AWSLoadBalancerControllerIAMPolicy" {
  depends_on  = [null_resource.policy]
  name        = "${local.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS LoadBalancer Controller IAM Policy"

  policy = file("iam_policy.json")
}

resource "aws_iam_role" "ek8s-AmazonEKSLoadBalancerControllerRole" {
  name = "${local.cluster_name}-AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Federated" : "${aws_iam_openid_connect_provider.default.arn}"
          },
          "Action" : "sts:AssumeRoleWithWebIdentity",
          "Condition" : {
            "StringEquals" : {
              "${aws_iam_openid_connect_provider.default.url}:aud" : "sts.amazonaws.com",
              "${aws_iam_openid_connect_provider.default.url}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
            }
          }
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "ek8s-AWSLoadBalancerControllerIAMPolicy" {
  policy_arn = aws_iam_policy.ek8s-AWSLoadBalancerControllerIAMPolicy.arn
  role       = aws_iam_role.ek8s-AmazonEKSLoadBalancerControllerRole.name
}

# Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = aws_eks_cluster.ek8s.name
  addon_name        = "vpc-cni"
  resolve_conflicts = "OVERWRITE"

  depends_on = [
    aws_iam_role_policy_attachment.ek8s-AmazonEKS_CNI_Policy,
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.ek8s.name
  addon_name        = "coredns"
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name      = aws_eks_cluster.ek8s.name
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"
}
