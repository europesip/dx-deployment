#!/bin/bash

# --- INPUT VALIDATION ---
if [ $# -lt 4 ]; then
    echo "❌ Error: Missing arguments."
    echo "Usage: $0 <REGISTRY_URL> <USERNAME> <PASSWORD> <PROJECT_NAME>"
    exit 1
fi

REGISTRY="$1"
USER="$2"
PASS="$3"
PROJECT="$4"

echo "---------------------------------------------------"
echo "🔐 1. Authenticating..."

# Login Podman (necesario para el push final)
echo "$PASS" | podman login "$REGISTRY" -u "$USER" --password-stdin
if [ $? -ne 0 ]; then echo "❌ Podman Login failed"; exit 1; fi

# Login Helm
echo "$PASS" | helm registry login "$REGISTRY" -u "$USER" --password-stdin
if [ $? -ne 0 ]; then echo "❌ Helm Login failed"; exit 1; fi

echo "✅ Auth OK. Target: $REGISTRY/$PROJECT"
echo "---------------------------------------------------"

# --- LOOP: IMAGES (Logic based on INTERNAL METADATA) ---
for f in *.tar.gz; do
    [ -e "$f" ] || continue
    
    echo "📦 Inspecting File: $f"
    
    # 1. USE SKOPEO TO READ INTERNAL TAG
    # We grab the first tag found in RepoTags array
    INTERNAL_TAG=$(skopeo inspect docker-archive:"$f" | jq -r '.RepoTags[0]')
    
    if [ "$INTERNAL_TAG" == "null" ] || [ -z "$INTERNAL_TAG" ]; then
        echo "⚠️  Could not read internal RepoTags for $f. Skipping."
        continue
    fi
    
    echo "   🔍 Internal Identity: $INTERNAL_TAG"
    
    # 2. PARSE THE INTERNAL NAME
    # Example Internal: localhost/hcl/content-composer:v1.45.0
    
    # Extract the Version (Tag) - everything after the last colon
    TAG="${INTERNAL_TAG##*:}"
    
    # Extract the Name part (remove the tag)
    NAME_PART="${INTERNAL_TAG%:*}"
    
    # Clean the Name: Remove known prefixes (localhost/, hcl/, docker.io/)
    # We take only the last part of the path (basename) to be safe
    # hcl/content-composer -> content-composer
    CLEAN_NAME=$(basename "$NAME_PART")
    
    # 3. CONSTRUCT TARGET NAME
    # Matches your YAML expectation: registry/dx/content-composer:v1.45...
    TARGET_IMAGE="$REGISTRY/$PROJECT/$CLEAN_NAME:$TAG"
    
    echo "   🎯 Target Name:       $CLEAN_NAME"
    echo "   🏷️  Tag:               $TAG"
    
    # 4. LOAD, RETAG, PUSH (Using Podman)
    # Skopeo copy implies complexities with renaming on the fly without strict rules.
    # Loading to Podman ensures we handle the manifest correctly.
    
    podman load -i "$f" > /dev/null
    
    # Podman might have loaded it with the internal tag. We use that to retag.
    podman tag "$INTERNAL_TAG" "$TARGET_IMAGE"
    
    echo "   ⬆️  Pushing to: $TARGET_IMAGE"
    podman push "$TARGET_IMAGE"
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Success"
        podman rmi "$TARGET_IMAGE" "$INTERNAL_TAG" > /dev/null 2>&1
    else
        echo "   ❌ FAILED PUSH"
    fi
    echo "---------------------------------------------------"
done

# --- HELM CHARTS (No changes here) ---
echo "⚓ Processing HELM CHARTS..."
for h in *.tgz; do
    if [[ "$h" == *"hcl-dx"* ]] && [[ "$h" != *".tar.gz" ]]; then
        echo "   ⬆️  Pushing Chart: $h"
        helm push "$h" "oci://$REGISTRY/$PROJECT"
    fi
done

echo "🎉 DONE!"
