#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$ROOT_DIR/app/NYvoiceApp"
IDEAS_DIR="$ROOT_DIR/docs/ideas/20260226-icon-roughs"
ICONS_DIR="$APP_DIR/Resources/Icons"
ICONSET_DIR="$ICONS_DIR/AppIcon.iconset"

MASTER_SVG="$IDEAS_DIR/pulse-mic-minimal.svg"
TEMPLATE_SVG="$IDEAS_DIR/pulse-mic-template-18.svg"
TEMPLATE_PNG="$ICONS_DIR/MenuBarTemplate.png"
ICNS_OUT="$ICONS_DIR/AppIcon.icns"

for cmd in rsvg-convert iconutil; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
done

if [ ! -f "$MASTER_SVG" ]; then
  echo "error: master svg not found: $MASTER_SVG" >&2
  exit 1
fi

if [ ! -f "$TEMPLATE_SVG" ]; then
  echo "error: template svg not found: $TEMPLATE_SVG" >&2
  exit 1
fi

mkdir -p "$ICONSET_DIR"

render() {
  local size="$1"
  local out="$2"
  rsvg-convert -w "$size" -h "$size" "$MASTER_SVG" -o "$out"
}

render 16 "$ICONSET_DIR/icon_16x16.png"
render 32 "$ICONSET_DIR/icon_16x16@2x.png"
render 32 "$ICONSET_DIR/icon_32x32.png"
render 64 "$ICONSET_DIR/icon_32x32@2x.png"
render 128 "$ICONSET_DIR/icon_128x128.png"
render 256 "$ICONSET_DIR/icon_128x128@2x.png"
render 256 "$ICONSET_DIR/icon_256x256.png"
render 512 "$ICONSET_DIR/icon_256x256@2x.png"
render 512 "$ICONSET_DIR/icon_512x512.png"
render 1024 "$ICONSET_DIR/icon_512x512@2x.png"

rsvg-convert -w 18 -h 18 "$TEMPLATE_SVG" -o "$TEMPLATE_PNG"

if iconutil -c icns "$ICONSET_DIR" -o "$ICNS_OUT" 2>/dev/null; then
  echo "generated: $ICNS_OUT"
else
  echo "warning: iconutil failed with Invalid Iconset in current environment; iconset PNGs were generated." >&2
fi

echo "generated: $TEMPLATE_PNG"
