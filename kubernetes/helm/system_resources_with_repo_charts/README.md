# Application chart

This chart includes base components for a cluster, i.e. dashboardUI, ingress, and so on.

First add the required dependend repositories:
```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Then update the dependencies with:
```bash
helm dependency update .
```

Then review values and install with:
```bash
helm install system-resource . --values your-values.yaml
```