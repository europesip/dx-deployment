# HCL Digital Experience – OpenShift Installation Guide
**DX 9.5 CF231 – EuropeSIP Lab Cluster**

This document provides a clear, structured, and repeatable procedure for collecting diagnostic logs from an HCL DX installation.
These logs are essential for providing HCL Support with accurate system information, enabling effective analysis and troubleshooting of potential issues.

---


# TROUBLESHOOTING – LOG COLLECTION

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

As an alternative to running each command manually, this repository includes a helper script named collect_logs.sh.
This script automates the entire log-collection workflow and generates a timestamped folder containing all relevant diagnostics, allowing you to gather complete support information with a single command:
```bash
./collect_logs.sh digital-experience dx-deployment
```
