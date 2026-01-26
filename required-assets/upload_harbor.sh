#!/bin/bash

# --- INPUT VALIDATION ---
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
echo "🚀 Starting SKOPEO Pattern-Based Upload"
echo "   Target Registry: $REGISTRY/$PROJECT"
echo "---------------------------------------------------"

# 1. SKOPEO LOGIN
# We pass the password via stdin to keep it secure
echo "$PASS" | skopeo login "$REGISTRY" -u "$USER" --password-stdin
if [ $? -ne 0 ]; then
    echo "❌ Skopeo Login Failed."
    exit 1
fi

# 2. HELM LOGIN (For the charts)
echo "$PASS" | helm registry login "$REGISTRY" -u "$USER" --password-stdin > /dev/null 2>&1

echo "✅ Authentication OK. Processing files..."
echo "---------------------------------------------------"

# --- LOOP THROUGH .tar.gz FILES ---
for f in *.tar.gz; do
    # Check if file exists
    [ -e "$f" ] || continue

    # --- PATTERN EXTRACTION LOGIC ---
    # File format: hcl-dx-[NAME]-image-[TAG].tar.gz
    
    # 1. Extract TAG (Right side of "-image-")
    # "hcl-dx-haproxy-image-v1.28.tar.gz" -> "v1.28.tar.gz"
    TEMP_TAG="${f##*-image-}"
    # Remove extension -> "v1.28"
    TAG="${TEMP_TAG%.tar.gz}"
    
    # 2. Extract NAME (Left side of "-image-")
    # "hcl-dx-haproxy-image-v1.28.tar.gz" -> "hcl-dx-haproxy"
    TEMP_NAME="${f%-image-*}"
    # Remove prefix "hcl-dx-" -> "haproxy"
    COMPONENT_NAME="${TEMP_NAME#hcl-dx-}"
    
    # 3. SPECIAL RENAMING RULES (EXCEPTIONS)
    # If a filename doesn't perfectly match the YAML expectation, fix it here.
    # Based on your lists, "digital-asset-manager" in file matches "digital-asset-manager" in YAML.
    # But if you have "search-middleware" file and need "remote-search", add a case here.
    
    case "$COMPONENT_NAME" in
        "digital-asset-manager")
            # Example: Ensure it matches dx/digital-asset-manager
            FINAL_NAME="digital-asset-manager"
            ;;
        *)
            FINAL_NAME="$COMPONENT_NAME"
            ;;
    esac

    # 4. CONSTRUCT DESTINATION
    # Format: registry/project/name:tag
    # Example: registry/dx/haproxy:v1.28...
    DESTINATION="docker://$REGISTRY/$PROJECT/$FINAL_NAME:$TAG"
    
    echo "📦 File: $f"
    echo "   🧩 Pattern applied:"
    echo "      -> Name: $FINAL_NAME"
    echo "      -> Tag:  $TAG"
    echo "   🚀 Uploading to: $DESTINATION"
    
    # 5. EXECUTE SKOPEO COPY
    # We use 'docker-archive' for source and 'docker://' for destination
    # --insecure-policy is often needed for local file archives to skip signature checks
    skopeo copy --insecure-policy \
        "docker-archive:$f" \
        "$DESTINATION"

    if [ $? -eq 0 ]; then
        echo "   ✅ OK"
    else
        echo "   ❌ FAILED"
    fi
    echo "---------------------------------------------------"
done

# --- HELM CHARTS UPLOAD ---
echo "⚓ Processing Helm Charts (.tgz)..."
for h in *.tgz; do
    # Filter only HCL charts, exclude images if they end in .tgz (rare but possible)
    if [[ "$h" == *"hcl-dx"* ]] && [[ "$h" != *"-image-"* ]]; then
        echo "   ⬆️  Pushing Chart: $h"
        helm push "$h" "oci://$REGISTRY/$PROJECT"
    fi
done

echo "🎉 DONE!"

