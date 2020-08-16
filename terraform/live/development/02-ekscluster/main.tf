module "ekscluster" {
  source                     = "../../../modules/ekscluster"
  env                        = "development"
  project                    = "ekspoc"
  cluster_name               = "ekspoc"
  vpc_id                     = "vpc-xxxxxx"
  subnet_id_az1              = "subnet-0001"
  subnet_id_az2              = "subnet-0002"
  ec2_ssh_key                = "my-ssh-key"
  want_multi_az_worker_nodes = false
  want_fargate               = false
  want_ec2_workers           = true
}