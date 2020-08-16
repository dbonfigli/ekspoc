#!/bin/bash

echo "requests per pod:"

kubectl get pods --no-headers --all-namespaces -o=custom-columns="NODE:.spec.nodeName,POD:.metadata.name,NAMESPACE:.metadata.namespace,CPUREQ:.spec.containers[*].resources.requests.cpu,MEMREQ:.spec.containers[*].resources.requests.memory"

echo
echo "total cpu requested per node (m cpu):"

kubectl get pods --no-headers --all-namespaces -o=custom-columns="NODE:.spec.nodeName,POD:.metadata.name,NAMESPACE:.metadata.namespace,CPUREQ:.spec.containers[*].resources.requests.cpu" | awk '
  $4 != "<none>" {
    split($4, requests, ",")
    for (i in requests) {
      if (substr(requests[i], length(requests[i])) != "m") {
        print "Error processing\n" $0
        exit 1
      } else {
        acc[$1] += substr(requests[i], 0, length(requests[i]) - 1)
      }
    }
  }
  END {
    for (i in acc) {
      print i "\t" acc[i]
    }
  }
'

echo
echo "total memory requested per node (MB):"

kubectl get pods --no-headers --all-namespaces -o=custom-columns="NODE:.spec.nodeName,POD:.metadata.name,NAMESPACE:.metadata.namespace,MEMREQ:.spec.containers[*].resources.requests.memory" | awk '
  $4 != "<none>" {
    split($4, requests, ",")
    for (i in requests) {
      if (substr(requests[i], length(requests[i])) != "i") {
        print "Error processing\n" $0
        exit 1
      } else {
        acc[$1] += substr(requests[i], 0, length(requests[i]) - 2)
      }
    }
  }
  END {
    for (i in acc) {
      print i "\t" acc[i]
    }
  }
'

echo
echo "info from describe nodes:"
kubectl describe nodes | grep -A 7 "Allocated resources:"