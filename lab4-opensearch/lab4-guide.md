# HCL DX Compose – Installing the New Search Engine on OpenShift  
## Lab Guide (DX 9.5 CF231)

> ⚠️ **DRAFT – Content Under Development**  
> This lab guide is not yet finalized. Instructions may change as the content evolves.

This lab explains the operational steps required to deploy and enable the **New Search Engine** for **HCL Digital Experience (DX) Compose** running on **OpenShift**.

---

## 📚 Official Documentation  
➡️ **HCL DX Documentation – Install the New Search Engine**  
https://help.hcl-software.com/digital-experience/9.5/CF231/deployment/install/container/helm_deployment/preparation/optional_tasks/optional_install_new_search/

---

# 📘 1. Objective

This guide provides the required steps to:

- Deploy the **DX Search Engine** as an additional component in DX Compose.
- Generate certificates and configure OpenSearch security.
- Integrate the new Search Engine into the existing DX Compose deployment.

### Prerequisites
- A fully functional **DX Compose** installation (→ complete Lab 1 first).  
- Permissions as `dxadmin` (or equivalent) on the OpenShift cluster.  
- Helm installed and configured on your workstation.  
- Storage available for the Search Engine deployment.  

> **Important:**  
This lab covers *operational setup only*.  
Any tuning or custom configuration must be applied via your own `custom-values.yaml`.

---

## 2. Login as installer

```bash
oc login https://api.promox.europesip-lab.com:6443 -u dxadmin
```


## 3. Confirm DX Installation Is Running

Before deploying Search, ensure the platform is fully operational:

```bash
oc project digital-experience
oc get pods
```

## 4. Create Secrets

```bash
# Root CA for certificates
openssl genrsa -out root-ca-key.pem 2048
openssl req -new -x509 -sha256 -key root-ca-key.pem -subj "/C=ES/O=EUROPESIP/OU=LAB/CN=opensearch" -out root-ca.pem -days 730
```

```bash
# Admin cert for OpenSearch configuration
openssl genrsa -out admin-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out admin-key.pem
openssl req -new -key admin-key.pem -subj "/C=ES/O=EUROPESIP/OU=LAB/CN=Admin" -out admin.csr
openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out admin.pem -days 730
```

```bash
# Node cert for inter node communication
openssl genrsa -out node-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in node-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out node-key.pem
openssl req -new -key node-key.pem -subj "/C=ES/O=EUROPESIP/OU=LAB/CN=opensearch-node" -out node.csr
openssl x509 -req -in node.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out node.pem -days 730
```

```bash
# Client cert for application authentication
openssl genrsa -out client-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in client-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out client-key.pem
openssl req -new -key client-key.pem -subj "/C=ES/O=EUROPESIP/OU=LAB/CN=opensearch-client" -out client.csr
openssl x509 -req -in client.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out client.pem -days 730
```

```bash
# Create kubernetes secrets
oc create secret generic search-admin-cert --from-file=admin.pem --from-file=admin-key.pem --from-file=root-ca.pem -n digital-experience
oc create secret generic search-node-cert --from-file=node.pem --from-file=node-key.pem --from-file=root-ca.pem -n digital-experience
oc create secret generic search-client-cert --from-file=client.pem --from-file=client-key.pem --from-file=root-ca.pem -n digital-experience
```

## 5 Extract and prepare Helm values

```bash
# Command to extract values.yaml from Helm Chart
helm show values hcl-dx-search-v2.29.0_20251027-1916.tgz > search-values.yaml
cp search-values.yaml custom-search-values.yaml 
```

Modify `custom-search-values.yaml` as needed. 
Note that a "custom-search-values-sample.yaml" is provided with the values we have use on this lab.
Optionally, you can overwrite the custom-search-values with that sample.
```bash
cp custom-search-values-sample.yaml custom-search-values.yaml 
```

---

## 6 Install DX Search

```bash
helm install -n digital-experience \
  -f custom-search-values.yaml \
  dx-search-deployment \
  ./hcl-dx-search-v2.29.0_20251027-1916.tgz \
  --timeout 20m \
  --wait
```

## 7 Check that the pods of the helm install are running correctly
```bash
oc get pods
oc get pv
```



## 8 Upgrade DX Compose helm deployment to use SearchMiddleware

If DX search was installed and is running correctly (as we can observe checking the pods), we can now upgrade DX to
add the SearchMiddleware integration.   To do so, we will update DX-Compose deployment, updating the corresponding references to search deployment 
Note that a "custom-values-sample.yaml" is provided with the values we have use on this lab.

Optionally, you can overwrite the custom-values with that sample.
```bash
cp custom-values-sample.yaml custom-values.yaml 
```
---
Once we have the custom-values.yaml  we need for DX Compose & DX Search integration, we may proceed doint the DX Upgrade


##
```bash
helm upgrade dx-deployment \
  -n digital-experience \
  -f custom-values.yaml \
  ./hcl-dx-deployment-2.42.1.tgz
```