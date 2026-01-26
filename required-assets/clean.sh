helm list
echo "Borrando previos labs"
helm uninstall dx-deployment
helm uninstall dx-search-deployment
oc get pvc
oc delete pvc --all -n digital-experience
oc get pv
oc get pv | grep 'digital-experience/' | awk '{print $1}' | xargs oc delete pv
