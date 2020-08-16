### oidc to let eks use iam

data "aws_region" "current" {}

data "external" "thumbprint" {
  program = ["${path.module}/resources/thumbprint.sh", data.aws_region.current.name ]
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = [ "sts.amazonaws.com" ]
  url             = aws_eks_cluster.this.identity.0.oidc.0.issuer
  thumbprint_list = [ data.external.thumbprint.result.thumbprint ]
}