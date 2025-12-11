# HCL Digital Experience – OpenShift Installation Guide
**DX 9.5 CF231 – EuropeSIP Lab Cluster**

This document provides a clear and repeatable procedure for cleaning and resetting previous DX deployments.
It allows the lab environment to be reused multiple times and supports training activities focused on DX installation and configuration.

---

# A. CLEANUP AND REMOVAL OF PREVIOUS INSTALLATIONS (as kubeadmin)

This section removes any previous DX installation so a fresh deployment can be executed.

---

## A.1 Login as cluster administrator

```bash
oc login https://api.promox.europesip-lab.com:6443 -u kubeadmin
oc project digital-experience
```

---

## A.2 Remove previous Helm deployment

```bash
helm list
helm uninstall dx-deployment
```

---

## A.3 Remove PVCs and PVs

```bash
oc get pvc
oc delete pvc --all -n digital-experience
```

Delete the PVs bound to the previous installation:

```bash
oc get pv
oc get pv | grep 'digital-experience/' | awk '{print $1}' | xargs oc delete pv
```


---

## A.4 Remove old pods and routes

```bash
oc get pods
oc get routes
oc delete route dx-deployment-passthrough
```

---

## A.5 Remove namespace

```bash
oc delete project digital-experience
```

---