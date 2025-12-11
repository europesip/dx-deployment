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

## A.4 Check StorageClasses

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

```bash
openssl genrsa -out my-key.pem 2048
openssl req -x509 -key my-key.pem -out my-cert.pem -days 365 -subj '/CN=EuropeSIP'
```

```bash
oc create secret tls dx-tls-cert --cert=my-cert.pem --key=my-key.pem -n digital-experience
```

---

## B.3 (Optional) Create registry PullSecret

This step is only necessary when using an image registry that requires authentication.  
In this lab environment, the OpenShift **internal registry** is used, so no additional ImagePullSecrets are required.

If your environment relies on an external or authenticated registry, you must create an appropriate PullSecret and reference it in your `custom-values.yaml`.

For further details, refer to the official HCL documentation:  
➡️ **[Optional ImagePullSecrets – HCL DX Documentation](https://help.hcl-software.com/digital-experience/dx-compose/CF231/deploy_dx/install/kubernetes_deployment/preparation/optional_tasks/optional_imagepullsecrets/)**

---

## B.4 Extract and prepare Helm values

```bash
helm show values hcl-dx-deployment-2.42.1.tgz > values.yaml
cp values.yaml custom-values.yaml
```

Modify `custom-values.yaml` as needed.
Note that a "custom-values-sample.yaml" is provided with the values we have use on this lab.

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
oc port-forward svc/dx-deployment-haproxy 8443:443
```

Now that you have done a "proxy" you can login trhough it  and check everyhing is running at <https://localhost:8443/wps/portal>
---

## B.8 Apply external OpenShift Route

```bash
oc apply -f dx-haproxy-route.yaml
```

You can now log in to your new DX installation by navigating to:  
<https://dx.apps.promox.europesip-lab.com/wps/myportal/>

If the deployment is incomplete or you encounter any issues, refer to the troubleshooting instructions in the **[logs.md](logs.md)** document.

Additionally, if you wish to repeat the lab, you can completely remove the deployment and start from a clean environment by following the cleanup steps provided in the **[clean.md](clean.md)** document.
