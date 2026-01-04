# Definir variables (igual que en tu script)
DOMAIN="europesip-lab.com"
COUNTRY="ES"
ORG="EuropeSIP"
OU="LAB"

echo "--- Generando Certificado para ORACLE DATABASE ---"

# 1. Generar Clave Privada y Solicitud (CSR)
openssl genrsa -out oracle-server.key 2048
openssl req -new -key oracle-server.key -out oracle-server.csr \
  -subj "/C=$COUNTRY/O=$ORG/OU=$OU/CN=oracle.$DOMAIN"

# 2. Crear archivo de extensiones (Vital para que funcione bien)
# Esto asegura que el certificado sirva para el nombre DNS correcto
cat <<EOF > oracle_ext.cnf
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = DNS:oracle.$DOMAIN, DNS:oracle
EOF

# 3. Firmar el certificado usando TU CA existente
openssl x509 -req -in oracle-server.csr \
  -CA europesip-ca.pem -CAkey europesip-ca.key -CAcreateserial \
  -out oracle-server.crt -days 825 -sha256 -extfile oracle_ext.cnf

echo "¡Certificado de Oracle generado!"
