resource "aws_lb" "ek8s" {
  name               = "alb-${local.cluster_name}"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets

  enable_cross_zone_load_balancing = true

  tags = {
    Name                       = "alb-${local.cluster_name}"
    "ingress.k8s.aws/resource" = "LoadBalancer"
    "ingress.k8s.aws/stack"    = var.k8s_ingress
    "elbv2.k8s.aws/cluster"    = local.cluster_name
  }

  lifecycle {
    ignore_changes = all
  }
}
