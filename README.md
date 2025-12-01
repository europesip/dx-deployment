# HCL Digital Experience – OpenShift Labs  
**DX 9.5 CF231 – EuropeSIP Lab Repository**

This repository contains a collection of hands-on laboratories designed to guide administrators and engineers through the installation, configuration, and operation of **HCL Digital Experience (DX) Compose** on **Red Hat OpenShift**.

Each lab focuses on a specific stage of the deployment lifecycle — from initial environment preparation to installation, routing, authentication, troubleshooting, log collection, and developer workflows.  
The objective is to provide a **clear, repeatable, and practical learning experience**, closely aligned with real-world OpenShift deployments.

These labs are publicly available to the community in this GitHub repository:

➡️ **https://github.com/europesip/dx-deployment**

You may clone the repository on your workstation using:

```bash
git clone https://github.com/europesip/dx-deployment.git
cd dx-deployment
```

Cloning the repository is highly recommended, as it allows you to:

- Run lab commands without manually copying them from a website
- Work with all YAML manifests locally and consistently
- Access the latest updates to guides, scripts, and sample configurations
- Use ready-to-run scripts (such as log collectors) without downloading them individually
- Avoid formatting or copy/paste errors during installation steps

---

## 📘 Repository Structure

The repository is organized into multiple lab modules.  
Each lab includes:

- Detailed step-by-step instructions  
- Required YAML manifests  
- Utility scripts for automation  
- Sample configuration files  
- Troubleshooting and diagnostic helpers  

---

## 🧪 Lab 1 – DX Base Setup  
⏱ **Estimated time: 30 minutes**  
📂 **Directory:** `lab1-dxsetup/`

Lab 1 covers the essential steps required to perform a **base installation of HCL DX Compose** on OpenShift.  
Topics include:

- Verifying environment prerequisites  
- Preparing required StorageClasses  
- Preparing or validating the image registry  
- Creating TLS certificates (self-signed or corporate)  
- Creating the DX namespace  
- Assigning RBAC roles (`kubeadmin` and `dxadmin`)  
- Installing DX using Helm  
- Creating an OpenShift Route for external access  

This lab serves as the foundation for all subsequent modules.
Upon completion, you will have a fully functional HCL DX Compose environment running on OpenShift and ready for use.

➡️ Start by following the instructions in: **[lab1-guide.md](lab1-dxsetup/lab1-guide.md)**

---

## 🧪 Lab 2 – DX Advanced Authentication  
⏱ Estimated time: **10 minutes**  
📂 **Directory:** `lab2-authentication/`

This lab (coming soon) will cover:

- Integration with corporate identity providers  
- SSO and OIDC configurations  
- External authentication workflows

---

## 🧪 Lab 3 – DX Corporate Database Integration  
⏱ Estimated time: **10 minutes**  
📂 **Directory:** `lab3-dbase/`

This lab (under construction) will demonstrate:

- Integration with corporate databases  
- Configuration of secure connections  
- Credential and secret management

---

## 🧪 Lab 4 – DX Advanced Search with OpenSearch  
⏱ Estimated time: **15 minutes**  
📂 **Directory:** `lab4-opensearch/`

This lab (under construction) will focus on:

- Connecting DX Compose to OpenSearch  
- Indexing and search configuration  
- Advanced content discovery scenarios

---

## 🧪 Lab 5 – DX Development Environment  
⏱ Estimated time: **20 minutes**  
📂 **Directory:** `lab5-development/`

This lab (under construction) will cover:

- Setting up **OpenShift Dev Spaces** for DX developers  
- Working with Git-based workflows  
- Using DX client tooling & Visual Studio Components inside Dev Spaces

---
