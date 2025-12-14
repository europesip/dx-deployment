#!/bin/bash
#*
#********************************************************************
#* Licensed Materials - Property of HCL                             *
#*                                                                  *
#* Copyright HCL Technologies Ltd. 2001, 2019. All Rights Reserved. *
#*                                                                  *
#* Note to US Government Users Restricted Rights:                   *
#*                                                                  *
#* Use, duplication or disclosure restricted by GSA ADP Schedule    *
#********************************************************************
#*


# Please see TN at https://support.hcl-software.com/csm?id=kb_article&sysparm_article=KB0094817
# Note:  We have modify the script provided at that TN,  to comment out the lines regarding DAMPV

#echo "Usage: bash ContainersMastgather.sh "
#echo -e "\nREQUIRED:"
#echo -e "  Name of your Namespace"
#echo -e "  Your cloud provider name"
#echo -e "  DX Core Presistant volume name"
#echo -e "  DAM persistant volume name"
#echo -e "  ./ContainersMastgather.sh dxns openshift dxcore-pv dam-pv"
#echo -e " Running action: Collecting configuration for dx-deployment"

NAMESPACE=digital-experience
CloudProvider=openshift
COREPV=pvc-b2c7a62c-e494-49b3-9d35-a694e6ba263a
#DAMPV=$4

echo -e "Running action: Collecting logs $NAMESPACE DX Deployment"

timestamp=$(date +%H%M%S_%d%m%Y)

mkdir container_mustgather_$timestamp

cd container_mustgather_$timestamp

if [ 'openshift' = $CloudProvider ]

then

echo "Cloud provider is " $CloudProvider

 oc version &>> kube-version.txt

 oc get nodes &>> nodes.txt

 oc describe customresourcedefinitions &>> CRD.txt

 oc get configmap dx-deployment -n $NAMESPACE -o yaml &>> configmap-dxdeployment.yaml
 
 oc get configmap dx-deployment-core -n $NAMESPACE -o yaml &>> configmap-dxdeployment-core.yaml

 oc get dxdeployment dx-deployment -n $NAMESPACE -o yaml &>> CR-dxdeployment.yaml
 
 oc get all -n $NAMESPACE &>> dx-resources.txt

 oc describe pv $COREPV -n $NAMESPACE &>> core-pv.yaml

 # oc describe pv $DAMPV -n $NAMESPACE &>> dam_pv.yaml
 
 oc get pv -n $NAMESPACE &>> DX-PV.txt
 
 oc get pvc -n $NAMESPACE &>> DX-PVC.txt
 
 oc get event -n $NAMESPACE &>> event.txt
 
 oc get pods -n $NAMESPACE --no-headers | grep -v Running | grep -v Completed | awk '{ print $1 }'  &>> non-running-pod.txt
 
cat non-running-pod.txt | while read line

do
   oc describe pod $line -n $NAMESPACE &>> $line.describe.txt
   oc logs $line -n $NAMESPACE &>> $line.log.txt
done
 
else

echo "Cloud provider is " $CloudProvider

 kubectl version &>> kube-version.txt

 kubectl get nodes &>> nodes.txt

 kubectl describe customresourcedefinitions &>> CRD.txt

 kubectl get configmap dx-deployment -n $NAMESPACE -o yaml &>> configmap-dxdeployment.yaml
 
 kubectl get configmap dx-deployment-core -n $NAMESPACE -o yaml &>> configmap-dxdeployment-core.yaml

 kubectl get dxdeployment dx-deployment -n $NAMESPACE -o yaml &>> CR-dxdeployment.yaml
 
 kubectl get all -n $NAMESPACE &>> dx-resources.txt

 kubectl describe pv $COREPV -n $NAMESPACE &>> core-pv.yaml

 kubectl describe pv $DAMPV -n $NAMESPACE &>> dam_pv.yaml
 
 kubectl get pv -n $NAMESPACE &>> DX-PV.txt
 
 kubectl get pvc -n $NAMESPACE &>> DX-PVC.txt

 kubectl get secrets -n  $NAMESPACE &>> DX-Secrets.txt
 
 kubectl get event -n $NAMESPACE &>> event.txt
 
 kubectl get pods -n $NAMESPACE --no-headers | grep -v Running | grep -v Completed | awk '{ print $1 }' &>> non-running-pod.txt
 
 
cat non-running-pod.txt | while read line
do
   kubectl describe pod $line -n $NAMESPACE &>> $line.describe.txt
   kubectl logs $line -n $NAMESPACE &>> $line.log.txt
done

echo "Logs have been collected, Please zip the folder and share to DX Support for review"
 
 
fi 
