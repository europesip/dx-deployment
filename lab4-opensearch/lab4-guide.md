# 🚀 HCL DX Compose: Installing the New Search Engine on OpenShift

## Lab Guide (DX 9.5 CF231)

> ⚠️ **DRAFT – Content Under Development**
> This lab guide is not yet finalized. Instructions may change as the content evolves.

This lab explains the operational steps required to deploy and enable the **New Search Engine** for **HCL Digital Experience (DX) Compose** running on **OpenShift**.

---

## 📚 Official Documentation

➡️ **HCL DX Documentation – Install the New Search Engine**
`https://help.hcl-software.com/digital-experience/9.5/CF231/deployment/install/container/helm_deployment/preparation/optional_tasks/optional_install_new_search/`

---

## 1. Objective

This guide provides the required steps to:

* Deploy the **DX Search Engine** as an additional component in DX Compose.
* Generate certificates and configure **OpenSearch** security.
* Integrate the new Search Engine into the existing DX Compose deployment.

### 1.1 Prerequisites

* A fully functional **DX Compose** installation (complete Lab 1 first).
* Permissions as `dxadmin` (or equivalent) on the OpenShift cluster.
* **Helm** installed and configured on your workstation.
* Sufficient storage available for the Search Engine deployment.

> **Important:**
> This lab covers *operational setup only*. Any tuning or custom configuration must be applied via your own `custom-values.yaml`.

### 1.2 🧑‍💻 Educational Scope Disclaimer

> The DX Search Engine is highly configurable and offers numerous advanced features. This guide is designed for **didactic and learning purposes** only, demonstrating the **basic functional setup**. For large-scale, corporate environments, high-volume indexing, or advanced search requirements, specialized **advanced tuning** and configuration (including resource allocation, sharding, and specific performance parameters) are strongly advised to achieve maximum performance and product capability.

---

## 2. Login as Installer

```bash
oc login https://api.promox.europesip-lab.com:6443 -u dxadmin
```


## 3. Confirm DX Installation Is Running

Before deploying the Search Engine, ensure that your DX Compose environment is fully operational:

```bash
oc project digital-experience
oc get pods

# All DX pods should be in Running state before continuing.
```

Check also you can login to DX compose at 

## 4. Generate Certificates and Create Secrets

The New Search Engine requires several certificates for secure communication. In this section, you will generate the required certificates and create the Kubernetes secrets to store them.

---

### 4.1 Generate Root CA

```bash
# Root CA for certificates
openssl genrsa -out root-ca-key.pem 2048
openssl req -new -x509 -sha256 -key root-ca-key.pem -subj "/C=ES/O=EUROPESIP/OU=LAB/CN=opensearch" -out root-ca.pem -days 730
```

### 4.2 Generate Admin Certificate

```bash
# Admin cert for OpenSearch configuration
openssl genrsa -out admin-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out admin-key.pem
openssl req -new -key admin-key.pem -subj "/C=ES/O=EUROPESIP/OU=LAB/CN=Admin" -out admin.csr
openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out admin.pem -days 730
```

### 4.3 Generate Node Certificate

```bash
# Node cert for inter node communication
openssl genrsa -out node-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in node-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out node-key.pem
openssl req -new -key node-key.pem -subj "/C=ES/O=EUROPESIP/OU=LAB/CN=opensearch-node" -out node.csr
openssl x509 -req -in node.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out node.pem -days 730
```

### 4.4 Generate Client Certificate

```bash
# Client cert for application authentication
openssl genrsa -out client-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in client-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out client-key.pem
openssl req -new -key client-key.pem -subj "/C=ES/O=EUROPESIP/OU=LAB/CN=opensearch-client" -out client.csr
openssl x509 -req -in client.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out client.pem -days 730
```

### 4.5  Create kubernetes secrets
```bash
oc create secret generic search-admin-cert --from-file=admin.pem --from-file=admin-key.pem --from-file=root-ca.pem -n digital-experience
oc create secret generic search-node-cert --from-file=node.pem --from-file=node-key.pem --from-file=root-ca.pem -n digital-experience
oc create secret generic search-client-cert --from-file=client.pem --from-file=client-key.pem --from-file=root-ca.pem -n digital-experience
```

## 5. Extract and Prepare Helm Values

Before installing the Search Engine, extract the default Helm chart values and prepare your customized configuration.

### 5.1 Extract default values from the Helm chart

```bash
helm show values hcl-dx-search-v2.29.0_20251027-1916.tgz > search-values.yaml
cp search-values.yaml custom-search-values.yaml
```

### 5.2 Customize the values file

Edit the file **custom-search-values.yaml** to adjust the Search Engine configuration for your environment  
(credentials, storage settings, resource limits, certificates, etc.).

A sample configuration used in this lab is on this repository, on the file custom-search-values-sample.yaml
If you want to use the sample as-is, you can overwrite your current values:
```bash
cp custom-search-values-sample.yaml custom-search-values.yaml 
```

---

## 6. Install DX Search

With your Helm values prepared, you can now install the DX Search Engine in your OpenShift environment.

```bash
helm install -n digital-experience \
  -f custom-search-values.yaml \
  dx-search-deployment \
  ./hcl-dx-search-v2.29.0_20251027-1916.tgz \
  --timeout 20m \
  --wait
```

### 6.1 Verify the Installation

After installing the DX Search Engine, ensure that all components are running correctly.

```bash
# Check all Search Engine pods
oc get pods -n digital-experience

# Check persistent volumes were bound correctly
oc get pv -n digital-experience
```

Expected results:

- All Search Engine pods should be in Running state.
- Persistent volumes should be Bound.
- No pods should be in CrashLoopBackOff.

Now, you shold be able to access the search API service at <https://dx.apps.promox.europesip-lab.com/dx/api/search/v2/explorer>
You can also access the new Search interface following the instructions at <https://help.hcl-software.com/digital-experience/9.5/CF231/build_sites/search_v2/access/>


## 7. Upgrade DX Compose Helm Deployment to Use SearchMiddleware

Once the DX Search Engine is installed and running correctly, integrate it with DX Compose by enabling the SearchMiddleware. This step updates the DX Compose deployment to reference the new Search Engine.

---

### 7.1 Prepare Custom Values for DX Compose

Ensure you have the correct `custom-values.yaml` for the DX Compose upgrade.  
For example, is critical that you have the specific settings for "searchMiddlewareService" integration and "uiV2Enabled"

You can use the sample provided in the lab:

```bash
cp custom-values-sample.yaml custom-values.yaml
```

Once we have the custom-values.yaml  we need for DX Compose & DX Search integration, we may proceed doing the DX Upgrade

---

### 7.2 Upgrade DX Compose Deployment

Perform the Helm upgrade to integrate DX Compose with the Search Engine:

```bash
helm upgrade dx-deployment \
  -n digital-experience \
  -f custom-values.yaml \
  ./hcl-dx-deployment-2.42.1.tgz
```

### 7.3 Verify Integration

After upgrading DX Compose, ensure that the integration with the Search Engine is working correctly:

1. Check that all DX Compose pods are running:

```bash
oc get pods -n digital-experience
```
2. Log in to DX as an administrator.

3. Navigate to Settings → Search to confirm that the New Search Engine is detected and active.

4. Optionally, create test content and verify that it is indexed correctly by the Search Engine.

### 7.4 Troubleshooting Tips

| Symptom | Possible Cause | Recommended Action |
|---------|----------------|------------------|
| DX cannot connect to Search | Incorrect client certificate or Helm values | Verify the `search-client-cert` secret and confirm that `custom-values.yaml` references are correct |
| Pods in CrashLoopBackOff | Incorrect Helm values or missing secrets | Compare with `custom-values-sample.yaml` and ensure all required secrets are created |
| Search not detected in DX | Upgrade did not apply correctly | Re-run the Helm upgrade with the correct namespace and values file |



