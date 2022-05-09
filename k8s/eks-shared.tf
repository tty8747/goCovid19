data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "tls_certificate" "ek8s" {
  url = aws_eks_cluster.ek8s.identity[0].oidc[0].issuer
}
