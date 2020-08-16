# aws-system-resources helm chart

This Chart is used to install basic resources that are commonly used but are not included at the start of the EKS cluster, such as GUI, ingress controller and so on.

# Calico Network Policy Engine

Calico add iptables rules to nodes, currently *it is not clear* ho to delete iptables rules create by calico when deleting calico network policy engine. We suggest here to first delete calico, then delete ANY network policy you created, and then reboot all the nodes.