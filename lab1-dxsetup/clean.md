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

```bash
oc get pv
```

Delete the PVs bound to the previous installation:

```bash
oc delete pv \
  pvc-272ca607-3d61-4178-ae6b-c3e680011b0a \
  pvc-50c04075-f1ca-4b53-bc39-d3d390a2207b \
  pvc-8edea03b-ded7-42c0-ab0a-de28e5818aed \
  pvc-db093249-4b07-4b49-96cd-cc24e107d6a2
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