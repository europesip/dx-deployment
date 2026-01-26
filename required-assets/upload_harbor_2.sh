#!/bin/bash

# --- VALIDACIÓN DE ARGUMENTOS ---
if [ $# -lt 4 ]; then
    echo "❌ Error: Missing arguments."
    echo "Usage: $0 <REGISTRY_URL> <USERNAME> <PASSWORD> <PROJECT_NAME>"
    echo "Example: $0 p32810yz.gra7.container-registry.ovh.net 'robot\$dx+dxuser' 'pass' dx"
    exit 1
fi

REGISTRY="$1"
USER="$2"
PASS="$3"
PROJECT="$4"

echo "---------------------------------------------------"
echo "🔐 1. Authenticating..."

# Login Podman
echo "$PASS" | podman login "$REGISTRY" -u "$USER" --password-stdin
if [ $? -ne 0 ]; then echo "❌ Podman Login failed"; exit 1; fi

# Login Helm
echo "$PASS" | helm registry login "$REGISTRY" -u "$USER" --password-stdin
if [ $? -ne 0 ]; then echo "❌ Helm Login failed"; exit 1; fi

echo "✅ Auth OK. Target: $REGISTRY/$PROJECT"
echo "---------------------------------------------------"

# --- BUCLE: IMÁGENES DOCKER (PODMAN LOAD) ---
for f in *.tar.gz; do
    [ -e "$f" ] || continue
    
    echo "📦 Processing File: $f"
    
    # 1. LOAD IMAGE & CAPTURE OUTPUT
    # We use '2>&1' to capture both stdout and stderr just in case
    OUTPUT=$(podman load -i "$f" 2>&1)
    
    # 2. EXTRACT THE INTERNAL NAME
    # Podman says: "Loaded image: hcl/content-composer:v1.45"
    # We look for "Loaded image" (case insensitive) and take the last word
    INTERNAL_REF=$(echo "$OUTPUT" | grep -i "Loaded image" | awk '{print $NF}')
    
    if [ -z "$INTERNAL_REF" ]; then
        echo "⚠️  Could not detect image name in podman output for $f"
        echo "   (Debug Output: $OUTPUT)"
        continue
    fi
    
    echo "   🔍 Detected Internal Name: $INTERNAL_REF"

    # 3. CLEAN THE NAME (Logic for YAML matching)
    # The YAML wants: dx/content-composer
    # The Image usually has: hcl/content-composer or localhost/hcl/content-composer
    
    # Step A: Remove tag (everything after last colon)
    TAG="${INTERNAL_REF##*:}"
    # Step B: Remove tag from the string to get just the name part
    NAME_ONLY="${INTERNAL_REF%:*}"
    # Step C: Get the "basename" (last part of the path). 
    # e.g., "hcl/content-composer" -> "content-composer"
    SHORT_NAME=$(basename "$NAME_ONLY")
    
    # 4. CONSTRUCT FINAL TAG
    # registry.ovh/dx/content-composer:v1.45...
    FINAL_TAG="$REGISTRY/$PROJECT/$SHORT_NAME:$TAG"
    
    echo "   🎯 Re-tagging to: $FINAL_TAG"
    
    # 5. RETAG & PUSH
    podman tag "$INTERNAL_REF" "$FINAL_TAG"
    podman push "$FINAL_TAG"
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Push Success"
        # Cleanup to save space
        podman rmi "$FINAL_TAG" "$INTERNAL_REF" > /dev/null 2>&1
    else
        echo "   ❌ Push Failed"
    fi
    echo "---------------------------------------------------"
done

# --- HELM CHARTS ---
echo "⚓ Processing HELM CHARTS..."
for h in *.tgz; do
    # Skip .tar.gz images, only process charts
    if [[ "$h" == *"hcl-dx"* ]] && [[ "$h" != *".tar.gz" ]]; then
        echo "   ⬆️  Pushing Chart: $h"
        helm push "$h" "oci://$REGISTRY/$PROJECT"
    fi
done

echo "🎉 DONE!"

