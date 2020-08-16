#!/bin/bash
#from: https://github.com/terraform-providers/terraform-provider-aws/issues/10104

region=$1

THUMBPRINT=$(echo | openssl s_client -servername oidc.eks.$region.amazonaws.com -showcerts -connect oidc.eks.$region.amazonaws.com:443 2>&- | tail -r | sed -n '/-----END CERTIFICATE-----/,/-----BEGIN CERTIFICATE-----/p; /-----BEGIN CERTIFICATE-----/q' | tail -r | openssl x509 -fingerprint -noout | sed 's/://g' | awk -F= '{print tolower($2)}')

THUMBPRINT_JSON="{\"thumbprint\": \"${THUMBPRINT}\"}"

echo $THUMBPRINT_JSON