#!/bin/bash

# ------------------------------------------------------------
# OpenVSX robust downloader
# Intenta varias técnicas para evitar bloqueos por Cloudflare:
#  - User-Agent de navegador
#  - Headers de Firefox/Chrome
#  - Forzar IPv4
#  - Reintentos automáticos
#  - Validación de tamaño (VSIX real > 50 KB)
# ------------------------------------------------------------

if [ $# -ne 2 ]; then
  echo "Uso: $0 <publisher> <extension>"
  echo "Ejemplo: $0 redhat java"
  exit 1
fi

PUBLISHER=$1
EXT=$2
OUT="${PUBLISHER}.${EXT}.vsix"

echo "🔽 Descargando VSIX desde OpenVSX:"
echo "    Publisher: $PUBLISHER"
echo "    Extension: $EXT"
echo "    Salida:    $OUT"
echo

URL="https://open-vsx.org/api/${PUBLISHER}/${EXT}/latest/file/${PUBLISHER}.${EXT}.vsix"

# ---- FUNCIÓN DE DESCARGA AVANZADA ----

download_attempt() {
  curl -L \
       --ipv4 \
       -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36" \
       -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
       -H "Accept-Language: en-US,en;q=0.5" \
       -o "$OUT" \
       "$URL"
}

# ---- INTENTOS ----

for i in {1..5}; do
  echo "Intento $i/5..."
  download_attempt

  SIZE=$(wc -c < "$OUT")

  if [ "$SIZE" -gt 50000 ]; then
    echo "✅ Descargado correctamente ($SIZE bytes)."
    break
  else
    echo "⚠️ Archivo demasiado pequeño ($SIZE bytes). Probablemente es la página de error."
    echo "Reintentando en 3 segundos..."
    rm -f "$OUT"
    sleep 3
  fi
done

# Validación final
if [ ! -f "$OUT" ] || [ "$(wc -c < "$OUT")" -lt 50000 ]; then
  echo
  echo "❌ No fue posible descargar el VSIX desde OpenVSX."
  echo "   Es probable que OpenVSX esté bloqueando las peticiones."
  exit 1
fi

echo
echo "🎉 VSIX listo: $OUT"

