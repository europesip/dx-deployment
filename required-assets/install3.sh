cd ~/dx-deployment/lab3-authentication
oc get pods
echo Haciendo ahora lab3
cd 
helm upgrade dx-deployment   -n digital-experience   -f custom-values.yaml   ../required-assets/hcl-dx-deployment-2.43.0.tgz --reuse-values  --timeout 20m --wait


