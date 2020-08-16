variable "env" {
  description = "The name of the environment, e.g. development, staging, production..."
  type        = string
}

variable "project" {
  description = "name used to identify a project"
  type        = string
}

variable "cluster_name" {
  description = "name to be used to identify the cluster"
  type        = string
}

variable "vpc_id" {
  description = "id of the vcp where the server is"
  type        = string
}

variable "subnet_id_az1" {
  description = "subnet id for workers, az a"
  type        = string
}

variable "subnet_id_az2" {
  description = "subnet id for workers, az b"
  type        = string
}

variable "want_multi_az_worker_nodes" {
  description = "true if you want multi az nodes"
  type        = bool
}

variable "ec2_ssh_key" {
  description = "ssh key name to log in to the workers"
  type        = string
}

variable "ssh_access_worker_cidr" {
  description = "list of CIDRs that can connect to the workers via ssh"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "instance type for the server, e.g. m5.large... (keep in mind aws cni limits)"
  # to undestand how many pods in an instace type goes see https://docs.google.com/spreadsheets/d/1MCdsmN7fWbebscGizcK6dAaPGS-8T_dYxWp0IdwkMKI/edit?usp=sharing
  type        = string
  default     = "t3.large"
}

variable "want_fargate" {
  description = "true if you want to deploy pods on fargate"
  type        = bool
}

variable "want_ec2_workers" {
  description = "true if you want ec2 workers"
  type        = bool
}
