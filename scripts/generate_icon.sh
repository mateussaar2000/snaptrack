#!/bin/bash
set -e

# Generate a simple SnapTrack app icon into the iOS asset catalog.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/app/dime/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$OUT_DIR"

BASE_SIZE=1024
TMP_BASE=$(mktemp /tmp/snaptrack_icon_base.XXXXXX.png)

# Background rounded square with gradient
magick -size ${BASE_SIZE}x${BASE_SIZE} xc:none \
  -fill '#FF4F7D' -draw "roundrectangle 0,0 ${BASE_SIZE},${BASE_SIZE} 220,220" \
  \( +clone -sparse-color barycentric "0,0 #FF4F7D ${BASE_SIZE},${BASE_SIZE} #FF8C42" \) \
  -compose src_in -composite \
  "$TMP_BASE"

# Camera body (white rounded rectangle)
magick "$TMP_BASE" \
  -fill white \
  -draw "roundrectangle 212,302 812,722 90,90" \
  "$TMP_BASE"

# Lens outer ring (dark)
magick "$TMP_BASE" \
  -fill '#1C1C1E' \
  -draw "circle 512,512 512,380" \
  "$TMP_BASE"

# Lens inner circle (lighter)
magick "$TMP_BASE" \
  -fill '#3A3A3C' \
  -draw "circle 512,512 512,410" \
  "$TMP_BASE"

# Lens highlight
magick "$TMP_BASE" \
  -fill white \
  -draw "circle 560,460 560,440" \
  "$TMP_BASE"

# Flash dot
magick "$TMP_BASE" \
  -fill white \
  -draw "circle 720,380 720,360" \
  "$TMP_BASE"

# Remove old icon files, keep Contents.json
find "$OUT_DIR" -maxdepth 1 -type f \( -name '*.png' \) ! -name 'Contents.json' -delete

# Copy final base as marketing icon
cp "$TMP_BASE" "$OUT_DIR/ios-marketing.png"

# Resize for all iOS entries defined in Contents.json
python3 <<PY
import json
import subprocess
from pathlib import Path

out_dir = Path('$OUT_DIR')
base = out_dir / 'ios-marketing.png'
with open(out_dir / 'Contents.json') as f:
    data = json.load(f)

for img in data['images']:
    filename = img.get('filename')
    size = img.get('size')
    scale = img.get('scale')
    platform = img.get('platform', 'ios')
    if not filename or not size or not scale:
        continue
    if platform != 'ios':
        continue
    w, h = map(float, size.split('x'))
    s = int(scale.replace('x', ''))
    px = int(w * s)
    out_file = out_dir / filename
    subprocess.run([
        'magick', str(base),
        '-resize', f'{px}x{px}',
        '-background', 'none',
        '-gravity', 'center',
        '-extent', f'{px}x{px}',
        str(out_file)
    ], check=True)
    print(f'Generated {filename} ({px}x{px})')
PY

rm -f "$TMP_BASE"
echo "✅ App icon generated in $OUT_DIR"
