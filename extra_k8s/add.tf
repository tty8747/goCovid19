# Amazon load balancer controller
resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.ek8s.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }
}

# NGINX Ingress as a variant
# https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/
# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/annotations/
# https://aws.amazon.com/blogs/opensource/network-load-balancer-nginx-ingress-controller-eks/
# resource "helm_release" "nginx_ingress" {
#   name      = "nginx-ingress"
#   namespace = "kube-system"
#
#   repository = "https://helm.nginx.com/stable"
#   chart      = "nginx-ingress"
#
#   set {
#     name  = "kubernetes.io/ingress.class"
#     value = "alb"
#   }
#
#   set {
#     name  = "alb.ingress.kubernetes.io/ip-address-type"
#     value = "ipv4"
#   }
#
#   set {
#     name  = "alb.ingress.kubernetes.io/scheme"
#     value = "internet-facing"
#   }
#
#   set {
#     name  = "alb.ingress.kubernetes.io/target-type"
#     value = "ip"
#   }
# }

# --- kubernetes

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = data.aws_iam_role.AmazonEKSLoadBalancerControllerRole.arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

# --- kubectl

# autoscalling
# https://www.reddit.com/r/aws/comments/gzkzph/eksterraform_how_to_setup_aws_autoscaling_policy/
data "kubectl_file_documents" "autoscaling_yaml" {
  content = templatefile("${path.module}/cluster-autoscaler-autodiscover.yml.tftpl",
    {
      account_id                         = data.aws_caller_identity.current.account_id
      cluster_name                       = data.aws_eks_cluster.ek8s.name
      amazon_eks_cluster_autoscaler_role = "${data.aws_eks_cluster.ek8s.name}-AmazonEKSClusterAutoscalerRole"
    }
  )
}

# https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html
resource "kubectl_manifest" "autoscaling_yaml" {
  # Set 6 to avoid this error: The "for_each" value depends on resource attributes that cannot be determined until apply, so Terraform cannot predict how many instances will be created.
  count = 6
  # count     = length(data.kubectl_file_documents.autoscaling_yaml.documents)
  yaml_body = element(data.kubectl_file_documents.autoscaling_yaml.documents, count.index)
}

# eks-metrics
data "kubectl_file_documents" "metrics-server" {
  content = file("metrics-server.yml")
}

resource "kubectl_manifest" "metrics-server" {
  for_each  = data.kubectl_file_documents.metrics-server.manifests
  yaml_body = each.value
}

# AWS Distro for OpenTelemetry to send metrics into CloudWatch
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-EKS-otel.html
data "kubectl_file_documents" "otel-container-insights" {
  content = file("otel-container-insights-infra.yml")
}

resource "kubectl_manifest" "otel-container-insights" {
  for_each  = data.kubectl_file_documents.otel-container-insights.manifests
  yaml_body = each.value
}

# Set up Fluent Bit as a DaemonSet to send logs to CloudWatch Logs
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs-FluentBit.html
resource "kubectl_manifest" "cloudwatch-namespace" {
  yaml_body = file("cloudwatch-namespace.yml")
}

resource "kubectl_manifest" "fluent-bit-configmap" {
  yaml_body = templatefile("${path.module}/fluent-bit-configmap.yml.tftpl",
    {
      cluster_name = data.aws_eks_cluster.ek8s.name
      region       = var.region
    }
  )
}

data "kubectl_file_documents" "fluent-bit" {
  content = file("fluent-bit.yml")
}

resource "kubectl_manifest" "fluent-bit" {
  for_each  = data.kubectl_file_documents.fluent-bit.manifests
  yaml_body = each.value
}
