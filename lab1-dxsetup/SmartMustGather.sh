#!/bin/bash
#*
#*
#* Script: Smart Container MustGather for HCL DX
#* Description: Automatically collects configuration, logs, and 
#* dynamic PV information for DX deployments.
#*

# --- CONFIGURATION & DEFAULTS ---
# Usage: ./script.sh [namespace] [release_name]
# If no arguments are provided, it defaults to 'digital-experience' and 'dx-deployment'
NAMESPACE=${1:-digital-experience}
RELEASE_NAME=${2:-dx-deployment}

timestamp=$(date +%H%M%S_%d%m%Y)
OUTPUT_DIR="container_mustgather_$timestamp"

# --- BINARY DETECTION (OC vs KUBECTL) ---
# Automatically detects if 'oc' is available; otherwise falls back to 'kubectl'
if command -v oc &> /dev/null; then
    CMD="oc"
    echo "OpenShift Client (oc) detected."
else
    CMD="kubectl"
    echo "Kubernetes Client (kubectl) detected."
fi

echo -e "\n========================================================"
echo -e " Running HCL DX MustGather"
echo -e " Namespace: $NAMESPACE"
echo -e " Release:   $RELEASE_NAME"
echo -e " Tool:      $CMD"
echo -e " Output:    $OUTPUT_DIR"
echo -e "========================================================\n"

mkdir -p $OUTPUT_DIR
cd $OUTPUT_DIR

# --- 1. CLUSTER INFO ---
echo "[1/6] Collecting Cluster & Node Info..."
$CMD version &>> kube-version.txt
$CMD get nodes -o wide &>> nodes.txt
$CMD top nodes &>> top-nodes.txt
$CMD describe customresourcedefinitions &>> CRD.txt

# --- 2. DX RESOURCES (ConfigMaps, CRs, Deployments) ---
echo "[2/6] Collecting DX Resources..."
$CMD get configmap -n $NAMESPACE -l release=$RELEASE_NAME -o yaml &>> configmaps-all.yaml
$CMD get dxdeployment -n $NAMESPACE -o yaml &>> CR-dxdeployment-all.yaml
$CMD get all -n $NAMESPACE &>> dx-resources.txt
$CMD get events -n $NAMESPACE --sort-by='.lastTimestamp' &>> events-sorted.txt
$CMD get secrets -n $NAMESPACE &>> secret-names.txt # Captures names only (content hidden for security)

# --- 3. STORAGE (DYNAMIC PV/PVC DETECTION) ---
# This section solves the issue of hardcoded PV names.
# It iterates through PVCs to find the specific PVs bound to this deployment.
echo "[3/6] Collecting Storage Information (Auto-detecting PVs)..."

# A. List all PVCs in the namespace
$CMD get pvc -n $NAMESPACE -o wide &>> DX-PVC-List.txt

# B. Iterate over each PVC to find its bound PV and describe it
echo "       -> Analyzing bound volumes..."
$CMD get pvc -n $NAMESPACE --no-headers | while read line; do
    # Extract PVC Name (Col 1) and Volume Name/PV (Col 3)
    PVC_NAME=$(echo $line | awk '{print $1}')
    PV_NAME=$(echo $line | awk '{print $3}')
    
    echo "          Found PVC: $PVC_NAME bound to PV: $PV_NAME"
    
    # Describe the PVC
    echo "--- PVC: $PVC_NAME ---" >> storage_details.yaml
    $CMD describe pvc $PVC_NAME -n $NAMESPACE >> storage_details.yaml
    
    # Describe the PV (Requires cluster-level permissions)
    echo "--- PV: $PV_NAME (Bound to $PVC_NAME) ---" >> storage_details.yaml
    $CMD describe pv $PV_NAME >> storage_details.yaml || echo "Warning: Could not describe PV $PV_NAME (Check permissions)" >> storage_details.yaml
done

# --- 4. POD ANALYSIS ---
echo "[4/6] Collecting Pod Status & Descriptions..."
$CMD get pods -n $NAMESPACE -o wide &>> podStatus.txt
$CMD top pods -n $NAMESPACE &>> top-pods.txt

# Identify pods that are NOT Running or Completed (e.g., CrashLoopBackOff, Error)
$CMD get pods -n $NAMESPACE --no-headers | grep -v "Running" | grep -v "Completed" | awk '{ print $1 }' > non-running-pods.list

if [ -s non-running-pods.list ]; then
    echo "       -> Found unhealthy pods. Gathering details..."
    cat non-running-pods.list | while read pod_name; do
        $CMD describe pod $pod_name -n $NAMESPACE > "issue_pod_${pod_name}_describe.txt"
        $CMD logs $pod_name -n $NAMESPACE --all-containers --tail=200 > "issue_pod_${pod_name}_recent_log.txt"
        # Try to get previous logs if the pod restarted
        $CMD logs $pod_name -n $NAMESPACE --all-containers --previous --tail=200 > "issue_pod_${pod_name}_PREVIOUS_log.txt" 2>/dev/null
    done
else
    echo "       -> All pods seem to be Running or Completed."
fi

# --- 5. LOGS COLLECTION ---
echo "[5/6] Collecting Application Logs..."

# General Logs (Current) - Captures logs for all pods in the release
$CMD logs -n $NAMESPACE -l release=$RELEASE_NAME --all-containers --prefix=true --tail=5000 > logs_all_current.txt

# General Logs (Previous) - Useful if any pod restarted recently
$CMD logs -n $NAMESPACE -l release=$RELEASE_NAME --all-containers --prefix=true --previous --tail=2000 > logs_all_previous.txt 2>/dev/null

# Web Engine Specific Logs (Critical for DX troubleshooting)
# Dynamically finds the web-engine pod name
WEB_POD=$($CMD get pods -n $NAMESPACE -l release=$RELEASE_NAME | grep web-engine | head -n 1 | awk '{print $1}')

if [ ! -z "$WEB_POD" ]; then
    echo "       -> Capturing full logs for primary Web Engine: $WEB_POD"
    $CMD logs $WEB_POD -c web-engine -n $NAMESPACE > log_web-engine-full.txt
    # Capture 'previous' log in case of CrashLoop
    $CMD logs -p $WEB_POD -c web-engine -n $NAMESPACE > log_web-engine-previous-crash.txt 2>/dev/null
else
    echo "       -> Warning: Could not auto-detect a web-engine pod."
fi

# --- 6. FINISH ---
cd ..
echo "[6/6] Compressing output..."
# Check if zip is installed, otherwise just warn
if command -v zip &> /dev/null; then
    zip -r "${OUTPUT_DIR}.zip" $OUTPUT_DIR > /dev/null
    echo -e "\n========================================================"
    echo -e " DONE!"
    echo -e " Archive created: ${OUTPUT_DIR}.zip"
    echo -e " Please upload this file to the HCL Support Case."
    echo -e "========================================================"
else
    echo -e "\n========================================================"
    echo -e " DONE!"
    echo -e " Output folder: $OUTPUT_DIR"
    echo -e " 'zip' command not found. Please compress the folder manually."
    echo -e "========================================================"
fi

