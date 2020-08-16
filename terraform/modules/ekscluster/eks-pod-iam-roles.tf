### role for ingress controller

resource "aws_iam_policy" "alb_ingress_controller_iam_policy" {
  name        = "${var.project}-${var.env}-${var.cluster_name}-EKSalbIngressControllerIamPolicy"
  path        = "/"
  description = "policy to allow ingress controller of eks to create alb"

  #policy got from https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/iam-policy.json
  policy = file("${path.module}/resources/ingress-iam-policy.json")
}

resource "aws_iam_role" "alb_ingress_controller_iam_role" {
  name               = "${var.project}-${var.env}-${var.cluster_name}-EKSalbIngressControllerIamRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = {
        Federated = "${aws_iam_openid_connect_provider.this.arn}"
      }
      Condition = {
        StringEquals = {
          replace("${aws_eks_cluster.this.identity.0.oidc.0.issuer}:sub", "https://", "") = "system:serviceaccount:kube-system:alb-ingress-controller"
        }
      }
    }]
  })

  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "alb_ingress_controller_policy_attachment" {
  policy_arn = aws_iam_policy.alb_ingress_controller_iam_policy.arn
  role       = aws_iam_role.alb_ingress_controller_iam_role.name
}

### for cration of dns records by ingress companion

resource "aws_iam_policy" "alb_ingress_external_dns_iam_policy" {
  name        = "${var.project}-${var.env}-${var.cluster_name}-EKSalbIngressExternalDNSIamPolicy"
  path        = "/"
  description = "policy to allow ingress controller of eks to create alb"

  #policy got from https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md#iam-permissions
  policy = file("${path.module}/resources/ingress-external-dns-iam-policy.json")
}

resource "aws_iam_role" "alb_ingress_external_dns_iam_role" {
  name               = "${var.project}-${var.env}-${var.cluster_name}-EKSalbIngressExternalDNSIamRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = {
        Federated = "${aws_iam_openid_connect_provider.this.arn}"
      }
    }]
  })

  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "alb_ingress_external_dns_policy_attachment" {
  policy_arn = aws_iam_policy.alb_ingress_external_dns_iam_policy.arn
  role       = aws_iam_role.alb_ingress_external_dns_iam_role.name
}

### test role

resource "aws_iam_role" "pod_s3_read_only_iam_role" {
  name               = "${var.project}-${var.env}-${var.cluster_name}-s3ReadOnly"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = {
        Federated = "${aws_iam_openid_connect_provider.this.arn}"
      }
    }]
  })

  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "pod_s3_read_only_iam_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.pod_s3_read_only_iam_role.name
}

### test role

resource "aws_iam_role" "pod_s3_read_write_iam_role" {
  name               = "${var.project}-${var.env}-${var.cluster_name}-s3ReadWrite"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = {
        Federated = "${aws_iam_openid_connect_provider.this.arn}"
      }
    }]
  })

  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "pod_s3_read_write_iam_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.pod_s3_read_write_iam_role.name
}

### role to allow prometheus notifications via sns

resource "aws_iam_policy" "alertmanager_sns_forwarder_iam_policy" {
  name        = "${var.project}-${var.env}-${var.cluster_name}-alertManagerSNSForwarderIamPolicy"
  path        = "/"
  description = "policy to allow sns forwarder to publish notifications"

  policy = file("${path.module}/resources/alertmanager-sns-forwarder-iam-policy.json")
}

resource "aws_iam_role" "alertmanager_sns_forwarder_iam_role" {
  name               = "${var.project}-${var.env}-${var.cluster_name}-alertManagerSNSForwarder"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = {
        Federated = "${aws_iam_openid_connect_provider.this.arn}"
      }
    }]
  })

  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "alertmanager_sns_forwarder_iam_policy_attachment" {
  policy_arn = aws_iam_policy.alertmanager_sns_forwarder_iam_policy.arn
  role       = aws_iam_role.alertmanager_sns_forwarder_iam_role.name
}

### role for cluster autoscaliner deployments

resource "aws_iam_policy" "cluster_autoscaler_iam_policy" {
  name        = "${var.project}-${var.env}-${var.cluster_name}-EKSClusterAutoScalerPolicy"
  path        = "/"
  description = "policy to allow worker node to scale"

  #policy got from https://aws.amazon.com/premiumsupport/knowledge-center/eks-cluster-autoscaler-setup/
  policy = file("${path.module}/resources/cluster-autoscaler-iam-policy.json")
}

resource "aws_iam_role" "cluster_autoscaler_iam_role" {
  name               = "${var.project}-${var.env}-${var.cluster_name}-clusterAutoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = {
        Federated = "${aws_iam_openid_connect_provider.this.arn}"
      }
    }]
  })

  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_iam_policy_attachment" {
  policy_arn = aws_iam_policy.cluster_autoscaler_iam_policy.arn
  role       = aws_iam_role.cluster_autoscaler_iam_role.name
}

### role for cloudwatch metrics adapter, to use external metrics from cloudwatch for HPA

resource "aws_iam_policy" "cloudwatch_metrics_adapter_iam_policy" {
  name        = "${var.project}-${var.env}-${var.cluster_name}-EKSCloudwatchMetricAdapterIamPolicy"
  path        = "/"
  description = "policy to allow worker node to scale"

  #policy got from https://github.com/awslabs/k8s-cloudwatch-adapter
  policy = file("${path.module}/resources/cloudwatch-metrics-adapter-iam-policy.json")
}

resource "aws_iam_role" "cloudwatch_metrics_adapter_iam_role" {
  name               = "${var.project}-${var.env}-${var.cluster_name}-CloudwatchMetricAdapter"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = {
        Federated = "${aws_iam_openid_connect_provider.this.arn}"
      }
    }]
  })

  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_metrics_adapter_iam_policy_attachment" {
  policy_arn = aws_iam_policy.cloudwatch_metrics_adapter_iam_policy.arn
  role       = aws_iam_role.cloudwatch_metrics_adapter_iam_role.name
}