cd ~/dx-deployment/lab4-opensearch
oc get pods
echo Haciendo ahora lab4
echo Instalando primero Dx-Search Deployment
helm install -n digital-experience -f custom-search-values.yaml dx-search-deployment ../required-assets/hcl-dx-search-v2.30.0.tgz --timeout 20m --wait
echo Actualizando Ahora Dx Deployment
helm upgrade dx-deployment   -n digital-experience   -f custom-values.yaml   ../required-assets/hcl-dx-deployment-2.43.0.tgz --reuse-values --timeout 20m --wait
echo Lab1, Lab2, Lab3 y Lab4  echos!!
