# HCL Digital Experience – OpenShift Installation Guide  
**DX 9.5 CF231 – EuropeSIP Lab Cluster**

Before starting the installation, the OpenShift administrator must ensure that the environment meets all required technical prerequisites.  
This involves preparing the necessary storage, configuring the container registry, setting up DNS entries, and providing an appropriate workstation from which the installation will be performed.

The administrator must complete the following tasks **before** beginning the installation:

---

### ✔ A Linux-based workstation / bastion

A workstation is required to run all installation commands. Any of the following options are valid:

- Linux workstation  
- WSL2 on Windows  
- A bastion VM with `kubectl`, `oc`, and `helm` installed  

This workstation must also have:

- Network access to the OpenShift cluster  
- Access to the image registry being used  
- Access to the DX Helm chart package (`hcl-dx-deployment-2.42.1.tgz`) locally or via shared storage  

---

### ✔ Required StorageClasses

The cluster must provide at least one **RWX** StorageClass and one **RWO** StorageClass for the DX deployment.

In this guide, we will use:

- `dx-deploy-rwx` — shared (ReadWriteMany) volumes  
- `dx-deploy-rwo` — persistent (ReadWriteOnce) volumes  

> **Note:**  
> You may use any existing StorageClass names in your environment by updating them in `custom-values.yaml`.  
> Since StorageClass provisioning differs across environments (NFS, ODF, SAN, cloud storage, etc.), **their creation and configuration are outside the scope of this guide** and are the responsibility of the OpenShift administrator.

---

### ✔ Container images available in the registry

The OpenShift administrator must preload all required HCL DX container images into the container registry used by the environment.

This process may involve:

- Pulling DX images from HCL’s distribution source  
- Tagging and pushing them into the organization’s registry  
- Ensuring OpenShift worker nodes can pull the images  
- Creating ImagePullSecrets if authentication is required  

> **Important:**  
> Because registry configuration varies significantly between customers and deployments — and corporate environments typically maintain a centralized registry with their own internal procedures —  
> **the process of uploading images to the registry is not covered in this guide**.  
> It is assumed that all required DX images are already present and accessible to the cluster.

---

### ✔ DNS hostname prepared

Before installing DX, the DNS administrator must configure the hostname that will be used to access the DX environment.

This includes:

- Creating the appropriate DNS record (typically an A or CNAME record)  
- Pointing it to the OpenShift ingress endpoint or load balancer  
- Ensuring that the hostname resolves correctly from the installer workstation and user networks  

> **Note:**  
> DNS configuration procedures vary across environments (internal DNS, cloud DNS, external providers, etc.),  
> therefore **the steps to create DNS entries are outside the scope of this guide**.

---

### ✔ Installer user (`dxadmin`)

This guide assumes that the `dxadmin` user already exists with the appropriate permissions to deploy DX inside the designated namespace.

Because user creation depends on the identity provider configured in the cluster (Azure AD, Keycloak, LDAP, htpasswd, etc.),  
**the creation and configuration of the `dxadmin` account are outside the scope of this guide** and must be performed by the OpenShift administrator before starting the installation.

### ✔ Optional: Clone the lab repository (recommended)

To simplify the installation process, you may optionally clone the public GitHub repository that contains:

- Updated installation instructions  
- Example configuration files  
- Sample `custom-values-sample.yaml`  
- Route definitions  
- Utility scripts used throughout the lab  
- Troubleshooting helpers  

Clone the repository with:

```bash
git clone https://github.com/europesip/dx-deployment.git
cd dx-deployment
```

After cloning the repository, you may also copy or download the Helm chart required for the installation  
(`hcl-dx-deployment-2.42.1.tgz`, as referenced at the beginning of this document).  
The Helm deployment package is available through HCL Software Downloads at:  
https://my.hcltechsw.com/downloads