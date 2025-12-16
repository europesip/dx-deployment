helm list
helm uninstall dx-deployment
helm uninstall dx-search
oc get pvc
oc delete pvc --all -n digital-experience
oc get pv
oc get pv | grep 'digital-experience/' | awk '{print $1}' | xargs oc delete pv
helm install -n digital-experience \
  -f custom-values.yaml \
  dx-deployment \
  ../required-assets/hcl-dx-deployment-2.42.1.tgz \
  --timeout 20m \
  --wait
echo Haciendo ahora lab2
cd ..
cd lab2-dbaseTransfer
helm upgrade dx-deployment   -n digital-experience   -f custom-values.yaml   ../required-assets/hcl-dx-deployment-2.42.1.tgz
cd ..
cd lab1-dxsetup

