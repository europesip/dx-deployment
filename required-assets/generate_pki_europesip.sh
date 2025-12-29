#!/bin/bash

# Configuración de nombres
DOMAIN="europesip-lab.com"
ORG="EuropeSIP"
OU="LAB"
COUNTRY="ES"

# Directorio de salida
mkdir -p pki_europesip
cd pki_europesip

echo "--- 1. Generando CA Raíz de EuropeSIP ---"
openssl genrsa -out europesip-ca.key 4096
openssl req -x509 -new -nodes -key europesip-ca.key -sha256 -days 3650 \
  -out europesip-ca.pem \
  -subj "/C=$COUNTRY/O=$ORG/OU=$OU/CN=$ORG $OU Root CA"

echo "--- 2. Generando Certificado para LDAP ---"
# Clave y CSR
openssl genrsa -out ldap-server.key 2048
openssl req -new -key ldap-server.key -out ldap-server.csr \
  -subj "/C=$COUNTRY/O=$ORG/OU=$OU/CN=ldap.$DOMAIN"

# Archivo de extensiones
cat <<EOF > ldap_ext.cnf
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = DNS:ldap.$DOMAIN
EOF

# Firma
openssl x509 -req -in ldap-server.csr -CA europesip-ca.pem -CAkey europesip-ca.key \
  -CAcreateserial -out ldap-server.crt -days 825 -sha256 -extfile ldap_ext.cnf

echo "--- 3. Generando Certificado para DB2 ---"
# Clave y CSR
openssl genrsa -out db2-server.key 2048
openssl req -new -key db2-server.key -out db2-server.csr \
  -subj "/C=$COUNTRY/O=$ORG/OU=$OU/CN=db2.$DOMAIN"

# Archivo de extensiones
cat <<EOF > db2_ext.cnf
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = DNS:db2.$DOMAIN
EOF

# Firma
openssl x509 -req -in db2-server.csr -CA europesip-ca.pem -CAkey europesip-ca.key \
  -CAcreateserial -out db2-server.crt -days 825 -sha256 -extfile db2_ext.cnf

echo "--- 4. Preparando archivos adicionales ---"
# Creamos un archivo combinado (chain) por si fuera necesario
cat ldap-server.crt europesip-ca.pem > ldap-fullchain.pem
cat db2-server.crt europesip-ca.pem > db2-fullchain.pem

echo "PROCESO FINALIZADO"
echo "Archivos generados en el directorio 'pki_europesip':"
ls -F
