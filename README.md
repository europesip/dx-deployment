# HCL Digital Experience – OpenShift Installation Guide
**DX 9.5 CF231 – EuropeSIP Lab Cluster**

This document provides a structured and repeatable procedure to:

- Clean and reset previous DX deployments  
- Prepare the OpenShift environment (as admin)  
- Install HCL DX using Helm (as dxadmin)  
- Validate access and configure external routing  
- Collect logs for troubleshooting  

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
oc delete route dx-route
```

---

## A.5 Remove namespace

```bash
oc delete project digital-experience
```

---

# B. PREREQUISITES SETUP (as kubeadmin)

Environment preparation prior to DX installation.

---

## B.1 Login and verify access

```bash
oc login https://api.promox.europesip-lab.com:6443 -u kubeadmin
oc whoami
```

---

## B.2 Validate cluster resources

```bash
oc adm top nodes
```

Requirements:

- **CPU:** ≥ 2 cores available  
- **Memory:** ≥ 8 GB free  

---

## B.3 Create namespace and assign permissions

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

## B.4 Check StorageClasses

```bash
oc get sc
```

---

# C. INSTALLATION PROCEDURE (as dxadmin)

---

## C.1 Login as installer

```bash
oc login https://api.promox.europesip-lab.com:6443 -u dxadmin
oc whoami
```

---

## C.2 Create TLS key & secret

```bash
openssl genrsa -out my-key.pem 2048
openssl req -x509 -key my-key.pem -out my-cert.pem -days 365 -subj '/CN=EuropeSIP'
```

```bash
oc create secret tls dx-tls-cert --cert=my-cert.pem --key=my-key.pem -n digital-experience
```

---

## C.3 (Optional) Create registry PullSecret

Documentation:  
https://help.hcl-software.com/digital-experience/dx-compose/CF231/deploy_dx/install/kubernetes_deployment/preparation/optional_tasks/optional_imagepullsecrets/

---

## C.4 Extract and prepare Helm values

```bash
helm show values hcl-dx-deployment-2.42.1.tgz > values.yaml
cp values.yaml custom-values.yaml
```

Modify `custom-values.yaml` as needed.

---

## C.5 Install DX

```bash
helm install -n digital-experience \
  -f custom-values.yaml \
  dx-deployment \
  ./hcl-dx-deployment-2.42.1.tgz \
  --timeout 20m \
  --wait
```

---

## C.6 Validate pod creation

```bash
oc get pods
oc logs -f dx-deployment-web-engine-0 -c web-engine -n digital-experience
```

---

## C.7 Validate HAProxy access (port-forward)

```bash
oc port-forward svc/dx-deployment-haproxy 8443:30443
```

---

## C.8 Apply external OpenShift Route

```bash
oc apply -f dx-haproxy-route.yaml
```

---

# D. TROUBLESHOOTING – LOG COLLECTION

Collect diagnostics if installation fails:

```bash
export namespace="digital-experience"
export releasename="dx-deployment"

kubectl -n $namespace top nodes > topnodes.txt
kubectl -n $namespace top pods > toppods.txt

kubectl get events -n $namespace > events.txt
kubectl get pods -n $namespace -o wide > podStatus.txt

kubectl logs -n $namespace -l release=$releasename --all-containers --prefix=true --previous --tail=-1 > previousLogs.txt
kubectl logs -n $namespace -l release=$releasename --all-containers --prefix=true --tail=-1 > currentLogs.txt
```

---

# ✔ Document Ready for Use
This README.md is prepared for exporting, publishing to GitHub/GitLab, or importing into documentation systems.
