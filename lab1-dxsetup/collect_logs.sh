#!/bin/bash

# ----------------------------
# DEFAULT VALUES
# ----------------------------
DEFAULT_NAMESPACE="digital-experience"
DEFAULT_RELEASE="dx-deployment"

# ----------------------------
# USAGE INFORMATION
# ----------------------------
print_usage() {
  echo "Usage: $0 [namespace] [release_name]"
  echo "Example: $0 dxspace dx-deployment"
  echo
  echo "No parameters were provided. Using default values:"
  echo "  Namespace: $DEFAULT_NAMESPACE"
  echo "  Release:   $DEFAULT_RELEASE"
  echo
}

# ----------------------------
# PARAMETER HANDLING
# If no parameters passed → print usage and use defaults.
# ----------------------------
if [ $# -eq 0 ]; then
  print_usage
fi

namespace="${1:-$DEFAULT_NAMESPACE}"
release="${2:-$DEFAULT_RELEASE}"

# ----------------------------
# CREATE TIMESTAMPED LOG FOLDER
# ----------------------------
timestamp=$(date +"%Y%m%d-%H%M%S")
logdir="logs/$timestamp"

mkdir -p "$logdir"

echo "Collecting logs for namespace: $namespace | release: $release"
echo "Logs will be stored in: $logdir"
echo

# ----------------------------
# TOP NODES
# ----------------------------
echo "Collecting node metrics..."
kubectl top nodes > "$logdir/nodes-top.txt" 2>&1

# ----------------------------
# POD METRICS
# ----------------------------
echo "Collecting pod metrics..."
kubectl top pods -n "$namespace" > "$logdir/pods-top.txt" 2>&1

# ----------------------------
# NAMESPACE EVENTS
# ----------------------------
echo "Collecting events..."
kubectl get events -n "$namespace" > "$logdir/events.txt" 2>&1

# ----------------------------
# POD STATUS
# ----------------------------
echo "Collecting pod status..."
kubectl get pods -n "$namespace" -o wide > "$logdir/pods-status.txt" 2>&1

# ----------------------------
# CONTAINER LOGS (PREVIOUS)
# ----------------------------
echo "Collecting previous logs... (CrashLoopBackOff, pre-restart errors)"
kubectl logs -n "$namespace" -l release="$release" \
  --all-containers --prefix=true --previous --tail=-1 \
  > "$logdir/previous-logs.txt" 2>&1

# ----------------------------
# CONTAINER LOGS (CURRENT)
# ----------------------------
echo "Collecting current logs..."
kubectl logs -n "$namespace" -l release="$release" \
  --all-containers --prefix=true --tail=-1 \
  > "$logdir/current-logs.txt" 2>&1

echo
echo "Done! Logs saved in: $logdir"
