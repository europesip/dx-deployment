helm list
helm uninstall dx-deployment
helm uninstall dx-search-deployment
oc get pvc
oc delete pvc --all -n digital-experience
oc get pv
oc get pv | grep 'digital-experience/' | awk '{print $1}' | xargs oc delete pv
helm install -n digital-experience \
  -f custom-values.yaml \
  dx-deployment \
  ../required-assets/hcl-dx-deployment-2.43.0.tgz \
  --timeout 20m \
  --wait
echo Haciendo ahora lab2
cd ..
cd lab2-dbaseTransfer
helm upgrade dx-deployment   -n digital-experience   -f custom-values.yaml   ../required-assets/hcl-dx-deployment-2.43.0.tgz --reuse-values --timeout 20m --wait
cd ..
echo Haciendo ahora lab3
cd lab3-authentication
helm upgrade dx-deployment   -n digital-experience   -f custom-values.yaml   ../required-assets/hcl-dx-deployment-2.43.0.tgz --reuse-values --timeout 20m --wait
cd ..
echo Haciendo ahora lab4
cd lab4-opensearch
helm install -n digital-experience -f custom-search-values.yaml dx-search-deployment ../required-assets/hcl-dx-search-v2.30.0.tgz --timeout 20m --wait
helm upgrade dx-deployment   -n digital-experience   -f custom-values.yaml   ../required-assets/hcl-dx-deployment-2.43.0.tgz --reuse-values
echo Lab1, Lab2, Lab3 y Lab4  echos!!
