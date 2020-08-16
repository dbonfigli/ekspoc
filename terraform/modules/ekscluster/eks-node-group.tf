### EKS worker node group

resource "aws_iam_role" "node_role" {
  name               = "${var.project}-${var.env}-${var.cluster_name}-eks-node-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_policy" "ebs_cni_iam_policy" {
  name        = "${var.project}-${var.env}-${var.cluster_name}-EKSEbsCniIamPolicy"
  path        = "/"
  description = "policy to allow worker node to create volumes"

  #policy got from https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/v0.4.0/docs/example-iam-policy.json
  policy = file("${path.module}/resources/ebs-cni-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "ebs_cni_iam_policy_attachment" {
  policy_arn = aws_iam_policy.ebs_cni_iam_policy.arn
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_security_group" "ssh_access_to_workers_sg" {
  name        = "${var.project}-${var.env}-${var.cluster_name}-ssh-access-to-workers-source-sg"
  description = "attach this security group to an instance to access eks worker via ssh"
  vpc_id      = var.vpc_id
  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_eks_node_group" "node_group_az1" {
  count           = var.want_ec2_workers ? 1 : 0
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project}-${var.env}-${var.cluster_name}-eks-nodegroup-az1"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [ var.subnet_id_az1 ]
  disk_size       = 20
  instance_types  = [ var.instance_type ]
  remote_access {
    ec2_ssh_key = var.ec2_ssh_key
    source_security_group_ids = [ aws_security_group.ssh_access_to_workers_sg.id ] #attach this sg to an instance to access worker via ssh
  }
  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }
  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

# if you use cluster autoscaling you cannot use an autoscaling group that span multiple zones, hence create multiple autoscaling groups, one for AZ
resource "aws_eks_node_group" "node_group_az2" {
  count           = var.want_multi_az_worker_nodes && var.want_ec2_workers ? 1 : 0 
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project}-${var.env}-${var.cluster_name}-eks-nodegroup-az2"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [ var.subnet_id_az2 ]
  disk_size       = 20
  instance_types  = [ var.instance_type ]
  remote_access {
    ec2_ssh_key = var.ec2_ssh_key
    source_security_group_ids = [ aws_security_group.ssh_access_to_workers_sg.id ] #attach this sg to an instance to access worker via ssh
  }
  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }
  tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}