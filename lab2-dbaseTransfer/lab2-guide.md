# 🚀 HCL DX Compose: Doing a DBTransfers

## Lab Guide (DX 9.5 CF231)

> ⚠️ **DRAFT – Content Under Development**
> This lab guide is not yet finalized. Instructions may change as the content evolves.

This lab explains the operational steps required to deploy and enable DB2
---

## 📚 Official Documentation

➡️ **HCL DX Documentation – Database Management**
<https://help.hcl-software.com/digital-experience/dx-compose/CF231/deploy_dx/manage/cfg_webengine/external_db_database_transfer/>

---

## 1. Objective

This guide provides the required steps to:

* Deploy the **LDAP Instegration** as authentication method in DX Compose.

### 1.1 Prerequisites

* A fully functional **DX Compose** installation (complete Lab 1 first).
* Permissions as `dxadmin` (or equivalent) on the OpenShift cluster.
* **Helm** installed and configured on your workstation.
* A external Database (on this lab Db2 will be user) with a user that can create the needed database


> **Important:**
> This lab covers *operational setup only*. Any tuning or custom configuration must be applied via your own `custom-values.yaml`.


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

## 4. Upgrade DX Compose Helm Deployment to Use LDAP

Once the DX Search Engine is installed and running correctly, you can integrate it with OpenLDAP. 
This step updates the DX Compose deployment to use and external OpenLDAP Server.

---

### 4.1 Prepare Custom Values for DX Compose

Ensure you have the correct `custom-values.yaml` for the DX Compose upgrade.  

You can use the sample provided in the lab:

```bash
cp custom-values-sample.yaml custom-values.yaml
```

Once we have the custom-values.yaml  we need for DX Compose & DX Search integration, we may proceed doing the DX Upgrade

---

### 4.2 Upgrade DX Compose Deployment

Perform the Helm upgrade to integrate DX Compose with the Search Engine:

```bash
helm upgrade dx-deployment \
  -n digital-experience \
  -f custom-values.yaml \
  ../required-assets/hcl-dx-deployment-2.42.1.tgz \
  --timeout 20m \
  --wait
```

### 4.3 Verify Integration

After upgrading DX Compose, ensure that the integration with the Search Engine is working correctly:

1. Check that all DX Compose pods are running:

```bash
oc get pods -n digital-experience
```
2. Log in to DX as an administrator.

3. Login in Portal using LDAP users

