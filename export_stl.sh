#!/usr/bin/env bash
set -euo pipefail

SCAD_FILE="Roco_Kato_Adapter.scad"
JSON_FILE="Roco_Kato_Adapter.json"
OUT_DIR="stl"

mkdir -p "$OUT_DIR"

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
    out="$OUT_DIR/${filename}.stl"
    echo "Exporting: $name -> $out"
    openscad -o "$out" -p "$JSON_FILE" -P "$name" "$SCAD_FILE"
done

echo "Done. STL files written to $OUT_DIR/"
