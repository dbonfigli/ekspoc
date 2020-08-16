# Monitoring Chart

This chart include the prometheus operator and prometheus rules to fire alarms.

update dependencies with:

```bash
helm dependency update .
```

and install with:
```bash
helm install test-prometheus .
```

Example of cpu used by all the pods in a deployment:
```
rate(container_cpu_usage_seconds_total{pod=~"deploymentname-.*", image!="",container_name!="POD"}[5m])
```