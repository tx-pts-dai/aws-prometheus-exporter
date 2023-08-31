data "aws_iam_policy_document" "get_vpc_ec2_metrics" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSubnets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "get_vpc_ec2_metrics" {
  name        = "get_vpc_ec2_metrics"
  description = "Allow to read ec2 data to get metrics out of it"
  policy      = data.aws_iam_policy_document.get_vpc_ec2_metrics.json
}

module "aws_prometheus_exporter" {
  source  = "aws-ia/eks-blueprints-addon/aws"
  version = "~> 1.0"

  name        = "aws-prometheus-exporter"
  chart       = "https://github.com/DND-IT/app-helm-chart/archive/refs/tags/3.4.0.tar.gz"
  namespace   = "prometheus"
  max_history = 10
  values = [
    templatefile("./helm_values/aws-prometheus-exporter.yaml", {
      image_tag        = "v0.1.0"
      aws_iam_role_arn = module.aws_prometheus_exporter.iam_role_arn
    })
  ]

  create_role = true
  role_name   = "aws-exporter"
  role_policies = {
    GetMetrics = aws_iam_policy.get_vpc_ec2_metrics.arn
  }
  create_policy = false # required if creating the policy (i.e. aws_iam_policy.this) outside the module

  oidc_providers = {
    this = {
      provider_arn    = module.eks.cluster_oidc_provider_arn
      service_account = "aws-prometheus-exporter"
    }
  }
}
