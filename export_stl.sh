#!/usr/bin/env bash
set -euo pipefail

SCAD_FILE="Roco_Kato_Adapter.scad"
JSON_FILE="Roco_Kato_Adapter.json"
OUT_DIR="stl"
IMG_DIR="img"

mkdir -p "$OUT_DIR" "$IMG_DIR"

# Extract parameter set names from the JSON file
mapfile -t PARAM_SETS < <(python3 -c "
import json, sys
with open('$JSON_FILE') as f:
    data = json.load(f)
for name in data['parameterSets']:
    print(name)
")

for name in "${PARAM_SETS[@]}"; do
    # Sanitize name for use as a filename (replace / and spaces with _)
    filename=$(echo "$name" | tr ' /°' '___' | tr -s '_' | sed 's/_$//')

    out_stl="$OUT_DIR/${filename}.stl"
    out_png="$IMG_DIR/${filename}.png"

    echo "Exporting: $name"

    openscad -o "$out_stl" -p "$JSON_FILE" -P "$name" "$SCAD_FILE"

    # PNG preview: isometric-ish view from above, full render for headless compat
    openscad -o "$out_png" \
        --export-format png \
        --camera=0,0,0,60,0,30,500 \
        --autocenter --viewall \
        --imgsize=600,400 \
        --projection=perspective \
        --render \
        -p "$JSON_FILE" -P "$name" "$SCAD_FILE"
done

echo "Done. STL files written to $OUT_DIR/, previews written to $IMG_DIR/"
