resource "aws_iam_role" "eks_fargate_pod_execution_role" {
  name  = "${var.project}-${var.env}-${var.cluster_name}-AmazonEKSFargatePodExecutionRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_pod_execution_role.name
}

resource "aws_eks_fargate_profile" "default-namespace" {
  count = var.want_fargate ? 1 : 0

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "default-namespace"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
  subnet_ids             = [ var.subnet_id_az1, var.subnet_id_az2 ]

  selector {
    namespace = "default"
    # match only pods with label runon: fargate
    # labels = {
    #   runon = "fargate"
    # }
  }

}

resource "aws_eks_fargate_profile" "kube-system" {
  count = var.want_fargate ? 1 : 0

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
  subnet_ids             = [ var.subnet_id_az1, var.subnet_id_az2 ]

  selector {
    namespace = "kube-system"
  }
}

# resource "aws_eks_fargate_profile" "coredns" {
#   count = var.want_fargate ? 1 : 0

#   cluster_name           = aws_eks_cluster.this.name
#   fargate_profile_name   = "coredns"
#   pod_execution_role_arn = aws_iam_role.eks_fargate_pod_execution_role.arn
#   subnet_ids             = [ var.subnet_id_az1, var.subnet_id_az2 ]

#   selector {
#     namespace = "kube-system"
#     labels = {
#       k8s-app = "kube-dns"
#     }
#   }

# }
