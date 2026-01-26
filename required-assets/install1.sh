cd ~/dx-deployment/required-assets
./clean.sh
cd ~/dx-deployment/lab1-dxsetup
echo "Instalando lab 1"
helm install -n digital-experience \
  -f custom-values.yaml \
  dx-deployment \
  ../required-assets/hcl-dx-deployment-2.43.0.tgz \
  --timeout 20m \
  --wait
