# HCL Digital Experience – OpenShift Installation Guide
**DX 9.5 CF231 – EuropeSIP Lab Cluster**

This document provides a structured and repeatable procedure to:

- Prepare the OpenShift environment (as admin)  
- Install HCL DX using Helm (as dxadmin)  
- Validate access and configure external routing  

---

# IMPORTANT

Before beginning the installation, the OpenShift administrator must ensure that the environment meets all required technical prerequisites.  
This includes preparing the storage infrastructure, configuring the image registry, and providing a suitable execution environment for the installer.

> **Note:**  
> This guide assumes that all required StorageClasses are already available, and that all necessary DX container images have been uploaded to the registry and are accessible to the cluster.  
> If you have any doubts regarding these prerequisites, please refer to **[pre-requisites.md](pre-requisites.md)**.

Once these foundational requirements are met, an authorized OpenShift administrator will prepare a dedicated namespace with restricted privileges, allowing the `dxadmin` user to safely perform the DX installation.  
If you need to repeat the lab, you can remove the deployment and start from a clean state by following the instructions in **[clean.md](clean.md)**.

This guide works with **two distinct roles**:

- The **OpenShift/Kubernetes cluster administrator**, typically associated with the `kubeadmin` user. This role is described in **Section A**.
- The **restricted installer user (`dxadmin`)**, responsible solely for deploying and managing HCL DX within the designated namespace. This role is covered in **Section B**.

You may assign these roles to two separate user accounts — a common practice in environments with strict security requirements — or use a single account for both, depending on your organization’s policies.

The steps required to prepare the environment are outlined below:

---

# A. PREREQUISITES SETUP (as kubeadmin - Cluster Admin privileges)

## A.1 Login as admin

```bash
oc login https://api.promox.europesip-lab.com:6443 -u kubeadmin
```

---

## A.2 Validate cluster resources

```bash
oc adm top nodes
```

Requirements:

- **CPU:** ≥ 2 cores available  
- **Memory:** ≥ 8 GB free  

---

## A.3 Create namespace and assign permissions

```bash
oc apply -f namespace-setup.yaml
```

Assign admin rights to dxadmin:

```bash
oc adm policy add-role-to-user admin dxadmin -n digital-experience
```

Apply extended RBAC:

```bash
oc apply -f rbac-extended.yaml
oc adm policy add-role-to-user dx-installer-extra-perms dxadmin -n digital-experience
```

---

## A.4 Configure Registry Authentication

While HCL distributes images via their official Harbor registry, air-gapped or enterprise environments typically require hosting images on a private internal registry.

To enable the Kubernetes cluster to authenticate and pull images from your private registry you must create a Docker Registry secret in the target namespace.

**Note:** The secret name below (`regcred`) must match the `imagePullSecrets` entry defined in your Helm `custom-values.yaml`.

```bash
oc create secret -n digital-experience docker-registry regcred \
  --docker-server=p32810yz.gra7.container-registry.ovh.net \
  --docker-username='robot$dx+dxuser' \
  --docker-password='XdNaDjuuTjUd3IphHESzfDaoX0IHCZ8F' \
  --docker-email='robot@dx.local'
```

---
## A.5 Check StorageClasses

```bash
oc get sc
```

---

# B. INSTALLATION PROCEDURE (as dxadmin, restricted namespace privileges)

Once the environment has been fully prepared and a namespace has been created where the `dxadmin` user has the required permissions, the installation can proceed.  
The user responsible for installing and managing the product will perform the following steps using the `dxadmin` account:

---

## B.1 Login as installer

```bash
oc login https://api.promox.europesip-lab.com:6443 -u dxadmin
```

---

## B.2 Create TLS key & secret

To enable HTTPS access to the platform, a Kubernetes TLS secret containing the certificate and private key is required. Choose one of the following options based on your environment.

### Option A: Self-Signed Certificate (Lab/Testing)

Use this method for laboratory environments or if you do not have a valid domain certificate yet. This will generate a warning in the browser but allows the traffic to be encrypted.

1.  **Generate the keys and certificate:**
    ```bash
    openssl genrsa -out my-key.pem 2048
    openssl req -x509 -key my-key.pem -out my-cert.pem -days 365 -subj '/CN=EuropeSIP'
    ```

2.  **Create the Secret:**
    ```bash
    oc create secret tls dx-tls-cert \
      --cert=my-cert.pem \
      --key=my-key.pem \
      -n digital-experience
    ```

---

### Option B: Existing Commercial Certificate (Production/Client)

Use this method if the client provides trusted certificates (e.g., from DigiCert, Let's Encrypt, or an internal Corporate PKI).

**1. Prepare the Full Chain File**
Kubernetes requires a **single file** containing the entire trust chain. If the client provided separate files (e.g., `domain.crt`, `intermediate.crt`, `root.crt`), you must concatenate them in the specific order shown below:

* **Order:** Server Certificate -> Intermediate CA -> Root CA

```bash
# Example command to merge certificates (Linux/Mac)
cat domain-name.crt intermediate-ca.crt root-ca.crt > full-chain.pem
```

Create the Secret Create the secret using the full chain file and the private key.
Note: Ensure the private key is unencrypted (no password).

```bash
oc create secret tls dx-tls-cert \
  --cert=full-chain.pem \
  --key=your-private-key.key \
  -n digital-experience
```

---

# B.3 Create WebEngine User & Password

```bash
oc create secret generic web-engine-secret --from-literal=username=wpsadmin --from-literal=password=Passw0rd
```

---


## B.4 Obtain the Deployment Helm Chart

To install the product and its components, we require two specific Helm Charts:
1.  **HCL DX Deployment Helm Chart**: For the core Digital Experience platform.
2.  **HCL Search Deployment Helm Chart**: For OpenSearch integrations and add-ons.

These packages contain all the necessary Kubernetes resource definitions and configuration templates.

First, ensure the destination directory exists and download the charts from the remote Harbor registry:

```bash
# 1. Create directory if it doesn't exist
mkdir -p ../required-assets

# 2. Download Core Deployment Chart
helm pull oci://p32810yz.gra7.container-registry.ovh.net/dx/hcl-dx-deployment \
  --version 2.43.0 \
  -d ../required-assets

# 3. Download Search Chart
helm pull oci://p32810yz.gra7.container-registry.ovh.net/dx/hcl-dx-search \
  --version 2.30.0 \
  -d ../required-assets
```

> **⚠️ Authentication Required**
> If the commands fail with an `unauthorized` error, you must authenticate with the registry first. Run the following command using the lab credentials:
> ```bash
> echo 'XdNaDjuuTjUd3IphHESzfDaoX0IHCZ8F' | helm registry login p32810yz.gra7.container-registry.ovh.net -u 'robot$dx+dxuser' --password-stdin
> ```

### ℹ️ Note on Local Download

While downloading the charts to your local machine is technically optional (you can invoke the installation directly from the Harbor registry using OCI syntax), **it is the recommended method for this laboratory**.

Downloading the charts allows you to **inspect their content** (by extracting the `.tgz` files) and understand how they are constructed. This is especially useful during the **Search configuration exercises**, where examining the structure of the `hcl-dx-search` chart and its dependencies provides valuable insight into the deployment architecture.
---

## B.5 Extract and prepare Helm values

```bash
helm show values ../required-assets/hcl-dx-deployment-2.43.0.tgz > values.yaml
cp values.yaml custom-values.yaml
```

Modify `custom-values.yaml` as needed.

OPTIONAL: A sample configuration used in this lab is on this repository, on the file custom-search-values-sample.yaml
If you want to use the sample as-is, you can overwrite your current values:
```bash
cp custom-values-sample.yaml custom-values.yaml 
```

---

## B.6 Install DX

```bash
helm install -n digital-experience \
  -f custom-values.yaml \
  dx-deployment \
  ../required-assets/hcl-dx-deployment-2.43.0.tgz \
  --timeout 20m \
  --wait
```

---

## B.7 Validate pod creation

```bash
oc get pods
oc logs -f dx-deployment-web-engine-0 -c web-engine -n digital-experience
```

---

## B.8 Validate HAProxy access (port-forward)

```bash
oc port-forward svc/dx-deployment-haproxy 8443:443
```

Now that you have done a "proxy" you can login trhough it  and check everyhing is running at <https://localhost:8443/wps/portal>
---

## B.9 Apply external OpenShift Route

```bash
oc apply -f dx-haproxy-route-main.yaml
```

You can now log in to your new DX installation by navigating to:  
<https://dx.apps.promox.europesip-lab.com/wps/myportal/>

If the deployment is incomplete or you encounter any issues, refer to the troubleshooting instructions in the **[logs.md](logs.md)** document.

Additionally, if you wish to repeat the lab, you can completely remove the deployment and start from a clean environment by following the cleanup steps provided in the **[clean.md](clean.md)** document.
