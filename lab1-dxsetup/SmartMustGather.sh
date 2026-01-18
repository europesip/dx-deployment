#!/bin/bash
#*
#*
#* Script: Smart Container MustGather for HCL DX (Enhanced)
#* Description: Automatically collects configuration, logs (current/prev),
#* dynamic PV info, and Environment Variables for critical pods.
#*

# --- CONFIGURATION & DEFAULTS ---
# Usage: ./script.sh [namespace] [release_name]
NAMESPACE=${1:-digital-experience}
RELEASE_NAME=${2:-dx-deployment}

timestamp=$(date +%H%M%S_%d%m%Y)
OUTPUT_DIR="container_mustgather_$timestamp"

# --- BINARY DETECTION (OC vs KUBECTL) ---
if command -v oc &> /dev/null; then
    CMD="oc"
    echo "OpenShift Client (oc) detected."
else
    CMD="kubectl"
    echo "Kubernetes Client (kubectl) detected."
fi

echo -e "\n========================================================"
echo -e " Running HCL DX MustGather (Enhanced)"
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

# --- 2. DX RESOURCES ---
echo "[2/6] Collecting DX Resources..."
$CMD get configmap -n $NAMESPACE -l release=$RELEASE_NAME -o yaml &>> configmaps-all.yaml
$CMD get dxdeployment -n $NAMESPACE -o yaml &>> CR-dxdeployment-all.yaml
$CMD get all -n $NAMESPACE &>> dx-resources.txt
$CMD get events -n $NAMESPACE --sort-by='.lastTimestamp' &>> events-sorted.txt
$CMD get secrets -n $NAMESPACE &>> secret-names.txt

# --- 3. STORAGE (DYNAMIC PV/PVC) ---
echo "[3/6] Collecting Storage Information..."
$CMD get pvc -n $NAMESPACE -o wide &>> DX-PVC-List.txt
$CMD get pvc -n $NAMESPACE --no-headers | while read line; do
    PVC_NAME=$(echo $line | awk '{print $1}')
    PV_NAME=$(echo $line | awk '{print $3}')
    echo "         Found PVC: $PVC_NAME bound to PV: $PV_NAME"
    echo "--- PVC: $PVC_NAME ---" >> storage_details.yaml
    $CMD describe pvc $PVC_NAME -n $NAMESPACE >> storage_details.yaml
    echo "--- PV: $PV_NAME (Bound to $PVC_NAME) ---" >> storage_details.yaml
    $CMD describe pv $PV_NAME >> storage_details.yaml || echo "Warning: Could not describe PV $PV_NAME" >> storage_details.yaml
done

# --- 4. POD ANALYSIS ---
echo "[4/6] Collecting Pod Status & Descriptions..."
$CMD get pods -n $NAMESPACE -o wide &>> podStatus.txt
$CMD top pods -n $NAMESPACE &>> top-pods.txt

# Identify unhealthy pods
$CMD get pods -n $NAMESPACE --no-headers | grep -v "Running" | grep -v "Completed" | awk '{ print $1 }' > non-running-pods.list
if [ -s non-running-pods.list ]; then
    echo "         -> Found unhealthy pods. Gathering details..."
    cat non-running-pods.list | while read pod_name; do
        $CMD describe pod $pod_name -n $NAMESPACE > "issue_pod_${pod_name}_describe.txt"
        $CMD logs $pod_name -n $NAMESPACE --all-containers --tail=200 > "issue_pod_${pod_name}_recent_log.txt"
        $CMD logs $pod_name -n $NAMESPACE --all-containers --previous --tail=200 > "issue_pod_${pod_name}_PREVIOUS_log.txt" 2>/dev/null
    done
fi

# --- 5. LOGS & ENV COLLECTION (SPECIFIC PODS) ---
echo "[5/6] Collecting Application Logs & Environments..."

# --- A. Web Engine ---
WEB_POD=$($CMD get pods -n $NAMESPACE -l release=$RELEASE_NAME | grep web-engine | head -n 1 | awk '{print $1}')
if [ ! -z "$WEB_POD" ]; then
    echo "         -> Capturing Web Engine: $WEB_POD"
    $CMD logs $WEB_POD -c web-engine -n $NAMESPACE > log_web-engine-full.txt
    $CMD logs -p $WEB_POD -c web-engine -n $NAMESPACE > log_web-engine-previous-crash.txt 2>/dev/null
else
    echo "         -> Warning: Web Engine pod not found."
fi

# --- B. HAProxy (Dynamic Detection) ---
HA_POD=$($CMD get pods -n $NAMESPACE -l release=$RELEASE_NAME | grep haproxy | head -n 1 | awk '{print $1}')
if [ ! -z "$HA_POD" ]; then
    echo "         -> Capturing HAProxy: $HA_POD"
    # Logs
    $CMD logs $HA_POD -n $NAMESPACE --all-containers > log_haproxy_current.txt
    $CMD logs -p $HA_POD -n $NAMESPACE --all-containers > log_haproxy_previous.txt 2>/dev/null
    # Env Vars (Only if running)
    echo "Attempting to capture ENV vars for HAProxy..."
    $CMD exec $HA_POD -n $NAMESPACE -- env > env_haproxy.txt 2>/dev/null || echo "Could not capture ENV (Pod likely not running)" > env_haproxy.txt
else
    echo "         -> Warning: HAProxy pod not found."
fi

# --- C. People Service (Dynamic Detection) ---
PEOPLE_POD=$($CMD get pods -n $NAMESPACE -l release=$RELEASE_NAME | grep peopleservice | head -n 1 | awk '{print $1}')
if [ ! -z "$PEOPLE_POD" ]; then
    echo "         -> Capturing People Service: $PEOPLE_POD"
    # Logs
    $CMD logs $PEOPLE_POD -n $NAMESPACE --all-containers > log_peopleservice_current.txt
    $CMD logs -p $PEOPLE_POD -n $NAMESPACE --all-containers > log_peopleservice_previous.txt 2>/dev/null
    # Env Vars (Crucial for DB config check)
    echo "Attempting to capture ENV vars for People Service..."
    $CMD exec $PEOPLE_POD -n $NAMESPACE -- env > env_peopleservice.txt 2>/dev/null || echo "Could not capture ENV (Pod likely not running)" > env_peopleservice.txt
else
    echo "         -> Warning: People Service pod not found."
fi

# --- 6. FINISH ---
cd ..
echo "[6/6] Compressing output..."
if command -v zip &> /dev/null; then
    zip -r "${OUTPUT_DIR}.zip" $OUTPUT_DIR > /dev/null
    echo -e "\n DONE! Archive created: ${OUTPUT_DIR}.zip"
else
    echo -e "\n DONE! Output folder: $OUTPUT_DIR (Please zip manually)"
fi
