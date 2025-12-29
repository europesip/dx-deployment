#!/bin/bash

# --- CONFIGURACIÓN ---
REGISTRY_HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
TARGET_PROJECT="openshift"

# --- MAPA CORREGIDO (SIN BARRAS /) ---
# Hemos cambiado "dx/nombre" por "dx-nombre" para que OpenShift lo acepte.
declare -A IMAGE_MAP
IMAGE_MAP["content-composer"]="dx-content-composer"
IMAGE_MAP["dam-plugin-google-vision"]="dx-dam-plugin-google-vision"
IMAGE_MAP["dam-plugin-kaltura"]="dx-dam-plugin-kaltura"
IMAGE_MAP["digital-asset-manager"]="dx-digital-asset-manager"
IMAGE_MAP["haproxy"]="dx-haproxy"
IMAGE_MAP["image-processor"]="dx-image-processor"
IMAGE_MAP["license-manager"]="dx-license-manager"
IMAGE_MAP["logging-sidecar"]="dx-logging-sidecar"
IMAGE_MAP["openldap"]="dx-openldap"
IMAGE_MAP["opensearch"]="dx-opensearch"
IMAGE_MAP["people-service"]="dx-people-service"
IMAGE_MAP["persistence-connection-pool"]="dx-persistence-connection-pool"
IMAGE_MAP["persistence-metrics-exporter"]="dx-persistence-metrics-exporter"
IMAGE_MAP["persistence-node"]="dx-persistence-node"
IMAGE_MAP["prereqs-checker"]="dx-prereqs-checker"
IMAGE_MAP["ringapi"]="dx-ringapi"
IMAGE_MAP["runtime-controller"]="dx-runtime-controller"
IMAGE_MAP["search-middleware"]="dx-search-middleware"
IMAGE_MAP["webengine"]="dx-webengine"
IMAGE_MAP["file-processor"]="dx-file-processor"
IMAGE_MAP["core"]="dx-core" # Faltaba el Core en la lista anterior
IMAGE_MAP["remote-search"]="dx-remote-search" # Faltaba remote search

echo "----------------------------------------------------------------"
echo "DESTINO: $REGISTRY_HOST/$TARGET_PROJECT"
echo "----------------------------------------------------------------"

for file in *.tar.gz; do
    echo ""
    echo "📦 Procesando archivo: $file"

    # 1. Cargar la imagen (Si ya está cargada, podman lo detecta rápido)
    LOAD_OUTPUT=$(podman load -i "$file")
    
    # Extraer nombre de imagen cargada
    # Buscamos la línea que dice "Loaded image:"
    LOADED_IMAGE=$(echo "$LOAD_OUTPUT" | grep "Loaded image" | awk '{print $3}')
    
    # Si podman dice "already exists", no nos da el nombre en la salida estándar a veces.
    # Intentamos deducirlo si LOADED_IMAGE está vacío.
    if [ -z "$LOADED_IMAGE" ]; then
        # Truco: Listar la última imagen cargada o buscar por el nombre del fichero
        # Como fallback, asumimos que el load funcionó y buscamos una imagen que coincida con el patrón hclcr
        echo "   ⚠️  Imagen ya cargada o output diferente. Buscando en podman images..."
        # Intentamos adivinar la imagen basándonos en el nombre del archivo (esto es un intento de recuperación)
        # Simplemente cogeremos el mapeo inverso si falla la detección automática, 
        # pero para simplificar, asumiremos que el usuario limpia imágenes o usa el output correcto.
        # Si falló la detección, saltamos para evitar errores graves.
        echo "   ❌ No pude detectar el nombre original. Asegúrate de que 'podman load' devuelve 'Loaded image'."
        continue
    fi
    
    echo "   -> Imagen original: $LOADED_IMAGE"

    # 2. Buscar en el mapa
    MATCH_FOUND=false
    for key in "${!IMAGE_MAP[@]}"; do
        if [[ "$file" == *"$key"* ]]; then
            TARGET_NAME=${IMAGE_MAP[$key]}
            MATCH_FOUND=true
            break
        fi
    done

    if [ "$MATCH_FOUND" = false ]; then
        echo "   ⚠️  AVISO: No tengo mapeado este archivo ($file). Saltando..."
        continue
    fi

    # 3. Extraer TAG y construir destino
    TAG=$(echo "$LOADED_IMAGE" | cut -d':' -f2)
    FINAL_IMAGE="$REGISTRY_HOST/$TARGET_PROJECT/$TARGET_NAME:$TAG"

    # 4. Retag y Push
    echo "   -> Retagging a: $FINAL_IMAGE"
    podman tag "$LOADED_IMAGE" "$FINAL_IMAGE"

    echo "   -> Subiendo a OpenShift..."
    podman push "$FINAL_IMAGE" --tls-verify=false

    if [ $? -eq 0 ]; then
        echo "   ✅ ÉXITO"
    else
        echo "   ❌ ERROR en el push"
    fi
done
