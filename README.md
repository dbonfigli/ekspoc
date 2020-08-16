# requirements

This poc must show these features of kubernetes:

- [x] kubernetes eks
- [x] provisioning with terraform
- [x] provisioning with cloudformation
- [x] iam users
- [x] external load balancer, internet facing, nlb, internal
- [x] ingress
- [x] native iam auth for pods
- [x] network overlay calico with network polices
- [x] node autoscaling with aws managed nodes (cluster autoscaling)
- [x] monitoring with metric server
- [x] dashboard
- [x] container insights
- [x] cloudwatch logging
- [x] hpa
- [x] vertical pod autoscaling
- [x] deployment with helm, helm secrets
- [x] ebs csi driver
- [x] fargate
- [x] monitoring with prometheus
- [x] alarmanager for allarms
- [x] grafana
- [x] hpa with custom metrics
- [ ] log aggregation with elasticsearch
- [ ] service mesh istio
- [ ] self managed nodes - golden ami
- [ ] replace VPC CNI

# Git

This repostiroy use submodules, clone it using the ```--recurse-submodules``` flag.

# Terrafor and Cloudformation

You can provision the basic aws resources (EKS cluster, nodes, iam policies) with terraform (for which definitions are in the "terraform" dir) or cloudformation (for which definitions are in the "cloudformation" dir).

# Instance type for workers

Please note that if you want to use aws cni, and a vpc ip for pod, then use an appropiate instance type for workers, normally each node come with 4 system pods, you cannot use a small t3 instance because if could not allocate more IPs / ENIs.

To get the number of pod a node can run:

```
kubectl get nodes -o custom-columns="NODE_NAME:metadata.name,MAX_PODS:status.capacity.pods"
```

# kubectl configuration

To configure kubectl, only with the user and profile used to create the cluster:

```
aws eks --region eu-west-1 update-kubeconfig --name ekspoc-development-ekspoc --profile company-test
```

do NOT specify --role-arn, like you see in examples in the aws documentation

# IAM authentication to cluster

At the creation of a EKS cluster only the user that created the cluster can access via IAM. Additional iam users can be configured via the configmap "aws-auth" in the "kube-system" namespace. This config map comes with the EKS and include the configuration to allow nodes to join the cluster, we don't want this config map to be messed by helm, we advise to get the initial definition with the command in the kubernetes directory:
```bash
kubectl get aws-auth -n kube-system -o yaml > aws-iam-auth/aws-iam-auth.yml
```
and modify this file that will be applyed with:
```bash
kubectl apply -f aws-iam-auth/aws-iam-auth.yml
```

# Miscellaneous K8S commands

get all resources for bk (not all indeed, e.g. ingresses are not there):

```
kubectl get all --all-namespaces -o yaml > kubernetes_all_objects_exported.yaml
```

restore:
```
kubectl create -f ./kubernetes_all_objects_exported.yaml
```

troubleshooting:
```
kubectl get events --sort-by='{.firstTimestamp}'
kubectl get nodes -o yaml
```

connect to a pod:
```
kubectl exec -it <podname> -- /bin/bash
```

monitoring (after installing metric server):
```
kubectl top node
kubectl top pod
```

access port in a pod:
```
kubectl --namespace default port-forward test-pod 8080:80
```

# Fargate

Set the terraform variable "want_fargate" to true to create fargate profiles that match pods to run on fargate (with profiles that match "default" and "kube-system" namespaces only). If you don't want ec2 workers, set "want_ec2_workers" to false, but, in this case, to make coredns work, you need to modify the deployment for the dns with the commands:

```bash
kubectl patch deployment coredns -n kube-system --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
kubectl rollout restart -n kube-system deployment coredns
```

To revert coredns:
```bash eks.amazonaws.com/compute-type : ec2
kubectl patch deployment coredns -n kube-system --type json -p='[{"op": "add", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type", "value": "ec2" }]'
kubectl rollout restart -n kube-system deployment coredns
```

Please note that:
* ingress must be of type ip (i.e. with the annotation: "alb.ingress.kubernetes.io/target-type: ip")
* volumes not supported (persistent-storage)
* the only ingress supported is of type application
* daemon set are not supported (logs must be shipped elsewhere via sidecar pattern)
* privileged pods are not supported
* network policies are not supported

# K8S system resources

Once the cluster is up you usually need to install additional resources to make it production ready, such as ingress controller, install container insights and so on. This can be done using either of the two methods:
- via the helm chart created for the occasion, system_resources, changing "values.yaml" in the ```kubernetes/helm/helm_vars/system_resources_vars/values.yaml``` with appropiate parameters and then:
```bash
helm install system-resources ./helm/system_resources --values helm/helm_vars/system_resources_vars/values.yaml
```
- via plaintext manifests, changing values in the manifests in the "system_resources_plain_manifests" dir and running the script:
```bash
./apply_system_resources_plain_manifests.sh
```

Actually, the same can be achieved using helm charts found on github, i.e. installing the required repositories:
```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm repo add bitnami https://charts.bitnami.com/bitnami
```

and the required charts (use your values):
```bash
kubectl create namespace helm-system
helm install aws-alb-ingress-controller incubator/aws-alb-ingress-controller
helm install external-dns bitnami/external-dns
helm install efs-provisioner stable/efs-provisioner
helm install cluster-autoscalier stable/cluster-autoscalier
helm install kubernetes-dashboard stable/kubernetes-dashboard
helm install metrics-server stable/metrics-server
```

In this list calico an container insights are still missing.

# Examples of functionality

You can use the manifests in the directoy "kubernetes/exaples_resource_files" to get examples used to test functionalities of EKS and K8S.

# External Load Balancer

To use an external load balancer:
- each subnet (public _and_ private) *must* be tagged with the tag ```kubernetes.io/cluster/<cluster-name>: shared```
- each private subnet *must* be tagged with the tag ```kubernetes.io/role/internal-elb: 1```
- each public subnet *must* be tagged with the tag ```kubernetes.io/role/elb: 1```

ref: https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html (note that the doc says "should", but to use an alb it is a _must_).

By default it is an internet facing classic load balancer, use the annotation:

```
service.beta.kubernetes.io/aws-load-balancer-internal: 0.0.0.0/0
```

for the service to create an internal load balancer, and the annotation:

```
service.beta.kubernetes.io/aws-load-balancer-type: nlb

```
for a network load balancer.

Network security:
- alb is created by the K8S load balaner service, as well as security group for it;
- eks automatically add the security group of the alb to the workers nodes.

Garbage collection:
- when you delete a service, the relative load balancer is deleted;
- when you change the annotation of the service so that a new type of load balancer is created, the old load balancer is *not* deleted.

# Ingress

Ingress is configured with rbac ad oid connection provider so that aws keys are not hardcoded in the ingress manifest, to troubleshoot ingress:
```
kubectl logs -n kube-system deployment.apps/alb-ingress-controller
```

DNS: you can automatically set up dns records using alb-ingress-external-dns.

# Pod IAM Roles

You can assign iam roles to pods: after the configuration of oidc, create a ServiceAccount with the annotation ```eks.amazonaws.com/role-arn: <role_arn>``` and use it in pods, see test-iam-role.yml for an example.

# Cluster Autoscaling

Details for the cluster autoscaler are at:
- https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md
- https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html

If you want cluster autoscaling you must create multiple auto scaling groups, one for AZ, you cannot span an asg in multiple AZs, for now, otherwise EBS volumes won't work (because if the autoscaler at one point scale down nodes so that remain only nodes in a single AZ, and EBS has been created in the other AZ, EBS volumes will not be mounted). In this case, also use the flag "--balance-similar-node-groups" in the deployment of the cluster autoscaler to balance nodes equally between multiple autoscaling groups.

To use cluser autoscaler the autoscaling group must have these tags:
- k8s.io/cluster-autoscaler/enabled: true
- k8s.io/cluster-autoscaler/awsExampleClusterName: owned (where awsExampleClusterName is the name of the eks cluster)

EKS node group automatically add these tags to the asg it creates.

# dashboard

```bash
kube proxy
```
then get the token for your iam user with:
```bash
aws eks get-token --cluster-name ekspoc-development-ekspoc --region eu-west-1 --profile company-test
```
then access the dashboard UI at:
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

# Vertical Pod Autoscaler

VPA is not native K8S functionality, but is achieved via custom definitions ([https://docs.aws.amazon.com/eks/latest/userguide/vertical-pod-autoscaler.html]). The custom definition is created via bash scripts taken from the official git repository for autoscaler (in this repository, a submodule in the kubernetes/autoscaler directory), To activate vertical pod autoscaler run this from the "kubernetes" directory:

```bash
autoscaler/vertical-pod-autoscaler/hack/vpa-up.sh
```

and to deactivate it:
```bash
autoscaler/vertical-pod-autoscaler/hack/vpa-down.sh
```

# EBS CSI Driver

The default storage class gp2 create an ebs volume by default.
If you want the new out-of-band ebs CSI driver, execute:
Deply the ebs CSI driver with:
```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/alpha/?ref=master"
```
(alpha is necessary to support IAM authentication for pods)
And use look at the example "test-ebs-external-storageClass.yml" to crete a pvc with the new storge class.

# Helm

Various examples of use of helm (and helm secrets) are under the directory "kubernetes/helm".

Lint helm files with:
```
helm lint ./test_application_1
```

Render the helm chart with:
```bash
 helm template ./test_application_1
```

install it with:
```bash
helm install my-test_application_1 ./test_application_1
```

install it with custom values:
```bash
helm install my-test_application_1 ./test_application_1 --values helm_vars/test_application_1/values.yaml
```

install in specific namespace:
```bash
helm install my-test_application_1 ./test_application_1 --namespace mynamespace
```

show it with:
```bash
helm ls --all
```

upgrade it with:
```bash
helm upgrade my-test_application_1 ./test_application_1
```

rollback to a version with:
```bash
helm rollback my-test_application_1 1
```

delete it with:
```bash
helm delete --purge my-test_application_1
```

to get the manifests of an installed release:
```bash
helm get manifest <release-name>
```

to get the objects of an installed release:
```bash
helm get manifest <release-name> | kubectl get -f -
```

to get the values of an installed release (use -a to show even the default values):
```bash
helm get values <release-name> -a
```

## Helm Secrets

To encrypt helm variables, you can use helm secrets (Doc at: [https://github.com/zendesk/helm-secrets]).

Install the dependency "sops" (in mac with ```brew install sops```) and install the helm plugin:
```bash
helm plugin install https://github.com/futuresimple/helm-secrets 
```

Then, you configure the file .sops.yaml to define how to encrypt secrets.yaml files, that will be merged when installing / upgrading helm charts.
Take the variables that must be enctypted, and move them in a file calle secret.yaml, then encrypt them with the command ```helm secrets enc secrets.yaml```, then, use the commands ```helm secrets``` instead of plain helm commands to manipulate helm, e.g. to install charts with encrypted values (e.g. ```helm secrets install test test_application_1 --values helm_vars/test_application_1_vars_with_enc_secrets/values.yaml --values helm_vars/test_application_1_vars_with_enc_secrets/secrets.yaml```), these commands will decrypt on the fly the secrets.yaml file and merge them into the values.

Never *ever* change the secret file by hand, because it is hashed by helm secrets, and the hash is checked when using it, always use ```helm secret edit``` instead.

## Dependencies between charts

To use dependent charts, define them in Charts.yaml, then, in the "master" chart directory, update dependencies with:
```bash
helm dependency update .
```
Set the values as usual, but using a map named as the child chart (e.g. if "redis" is a child chart, add "redis: val" to the values.yaml file).

# Monitoring with Prometheus

Run the following from the "kubernetes/helm" dir:
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install test-prometheus bitnami/prometheus-operator --values helm_prometheus-operator/values.yml
```
To install prometheus. (docs: https://github.com/helm/charts/tree/master/stable/prometheus-operator)

You can use the helmchart ```monitoring``` that create the helm operator and set up some testing alarms. This chart will use the prometheus operator, add alarms found in prometheusRules.yaml, create a unified ingress with prometheus and alert manager, and optionally creates a deployment to forward alarms via sns.
