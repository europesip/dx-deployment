# HCL Digital Experience – OpenShift Installation Guide
**DX 9.5 CF231 – EuropeSIP Lab Cluster**

This document provides a structured and repeatable procedure to:

- Prepare the OpenShift environment (as admin)  
- Install HCL DX using Helm (as dxadmin)  
- Validate access and configure external routing  

---

# A. PREREQUISITES SETUP (as kubeadmin)

Before starting the installation, the OpenShift administrator must ensure that the environment meets all technical prerequisites.  
This includes preparing storage, image registries, and providing an execution environment for the installer.

## A.0 Mandatory prerequisites (administrator responsibility)

The administrator must complete the following tasks **before** beginning the installation:

### ✔ A Linux-based workstation / bastion  
A machine must be available for running installation commands.  
Any of the following are valid:

- Linux workstation  
- WSL 2 on Windows  
- A bastion VM with kubectl, oc, and Helm installed  

This workstation must also have:

- Access to the OpenShift cluster  
- Access to the internal image registry  
- Access to the Helm chart package (`hcl-dx-deployment-2.42.1.tgz`) either locally or via shared storage

---

### ✔ Required StorageClasses  
The cluster must already have the necessary StorageClasses:

- **RWX** StorageClass for shared volumes  
- **RWO** StorageClass for persistent databases and logs  

> **Note:** This guide assumes that all required StorageClasses already exist.

---

### ✔ Images uploaded to the container registry  
The OpenShift administrator must preload the images required by the HCL DX deployment into the internal registry (or an external registry accessible by the cluster).

This may involve:

- Pulling images from HCL’s distribution source  
- Tagging and pushing them into the organization’s registry  
- Ensuring the registry is accessible from the OpenShift nodes  
- Creating required ImagePullSecrets (if necessary)

> **Assumption:**  
> All required DX images are already present in the registry and accessible to the cluster.

---

## A.1 Login and verify access

```bash
oc login https://api.promox.europesip-lab.com:6443 -u kubeadmin
oc whoami
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
oc project digital-experience
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

## A.4 Check StorageClasses

```bash
oc get sc
```

---

# B. INSTALLATION PROCEDURE (as dxadmin)

---

## B.1 Login as installer

```bash
oc login https://api.promox.europesip-lab.com:6443 -u dxadmin
oc whoami
```

---

## B.2 Create TLS key & secret

```bash
openssl genrsa -out my-key.pem 2048
openssl req -x509 -key my-key.pem -out my-cert.pem -days 365 -subj '/CN=EuropeSIP'
```

```bash
oc create secret tls dx-tls-cert --cert=my-cert.pem --key=my-key.pem -n digital-experience
```

---

## B.3 (Optional) Create registry PullSecret

Documentation:  
https://help.hcl-software.com/digital-experience/dx-compose/CF231/deploy_dx/install/kubernetes_deployment/preparation/optional_tasks/optional_imagepullsecrets/

---

## B.4 Extract and prepare Helm values

```bash
helm show values hcl-dx-deployment-2.42.1.tgz > values.yaml
cp values.yaml custom-values.yaml
```

Modify `custom-values.yaml` as needed.

---

## B.5 Install DX

```bash
helm install -n digital-experience \
  -f custom-values.yaml \
  dx-deployment \
  ./hcl-dx-deployment-2.42.1.tgz \
  --timeout 20m \
  --wait
```

---

## B.6 Validate pod creation

```bash
oc get pods
oc logs -f dx-deployment-web-engine-0 -c web-engine -n digital-experience
```

---

## B.7 Validate HAProxy access (port-forward)

```bash
oc port-forward svc/dx-deployment-haproxy 8443:30443
```

---

## B.8 Apply external OpenShift Route

```bash
oc apply -f dx-haproxy-route.yaml
```