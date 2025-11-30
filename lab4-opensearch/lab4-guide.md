# HCL DX Compose – New Search Engine Setup (OpenShift)

**DX 9.5 CF231 – Optional Search Engine Installation Lab**

This guide summarizes the essential steps required to deploy and enable the **new Search Engine** for HCL Digital Experience (DX) Compose on OpenShift.

Please note that this lab is not yet available, and is under DRAFT CONTENT  
The content is currently under development and will be released shortly.

Thank you for your patience.

For the full official documentation, please refer to:

➡️ **HCL DX Documentation – Install New Search Engine**  
https://help.hcl-software.com/digital-experience/9.5/CF231/deployment/install/container/helm_deployment/preparation/optional_tasks/optional_install_new_search/

---

## 📘 Overview

The new Search Engine replaces the legacy search service in HCL DX and is deployed as an additional component within your DX Compose environment.  
This lab assumes:

- You already have a working DX Compose installation.  
- You have permissions as `dxadmin` or equivalent to update the deployment.  
- You will **not** customize Helm values here — any configuration tuning must be performed separately in `custom-values.yaml`.

This document covers only the **operational steps** required to deploy and enable the new search service.

---

## 1. Login as installer

```bash
oc login https://api.promox.europesip-lab.com:6443 -u dxadmin
```


## 2. Confirm DX Installation Is Running

Before deploying Search, ensure the platform is fully operational:

```bash
oc project digital-experience
oc get pods
```

## 3. Create Secrets

```bash
# Root CA for certificates
openssl genrsa -out root-ca-key.pem 2048
openssl req -new -x509 -sha256 -key root-ca-key.pem -subj "/C=US/O=ORG/OU=UNIT/CN=opensearch" -out root-ca.pem -days 730
```

```bash
# Admin cert for OpenSearch configuration
openssl genrsa -out admin-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out admin-key.pem
openssl req -new -key admin-key.pem -subj "/C=US/O=ORG/OU=UNIT/CN=A" -out admin.csr
openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out admin.pem -days 730
```

```bash
# Node cert for inter node communication
openssl genrsa -out node-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in node-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out node-key.pem
openssl req -new -key node-key.pem -subj "/C=US/O=ORG/OU=UNIT/CN=opensearch-node" -out node.csr
openssl x509 -req -in node.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out node.pem -days 730
```

```bash
# Client cert for application authentication
openssl genrsa -out client-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in client-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out client-key.pem
openssl req -new -key client-key.pem -subj "/C=US/O=ORG/OU=UNIT/CN=opensearch-client" -out client.csr
openssl x509 -req -in client.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out client.pem -days 730
```

```bash
# Create kubernetes secrets
kubectl create secret generic search-admin-cert --from-file=admin.pem --from-file=admin-key.pem --from-file=root-ca.pem -n digital-experience
kubectl create secret generic search-node-cert --from-file=node.pem --from-file=node-key.pem --from-file=root-ca.pem -n digital-experience
kubectl create secret generic search-client-cert --from-file=client.pem --from-file=client-key.pem --from-file=root-ca.pem -n digital-experience
```

## 4 Extract and prepare Helm values

```bash
# Command to extract values.yaml from Helm Chart
helm show values hcl-dx-search.tar.gz > values.yaml
cp values.yaml custom-search-values.yaml
```

Modify `custom-search-values.yaml` as needed.
Note that a "custom-search-values-sample.yaml" is provided with the values we have use on this lab.

---

## 5 Install DX Search

```bash
helm install -n digital-experience \
  -f custom-search-values.yaml \
  dx-search-deployment \
  ./hcl-dx-search-vX.X.X_XXXXXXXX-XXXX.tar.gz \
  --timeout 20m \
  --wait
```
