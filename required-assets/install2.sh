cd ~/dx-deployment/lab2-dbaseTransfer
oc get pods
echo Haciendo ahora lab2
helm upgrade dx-deployment   -n digital-experience   -f custom-values.yaml ../required-assets/hcl-dx-deployment-2.43.0.tgz --reuse-values  --timeout 20m --wait


