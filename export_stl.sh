#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="stl"
IMG_DIR="img"

mkdir -p "$OUT_DIR" "$IMG_DIR"

# Export all parameter sets from one SCAD+JSON pair
export_param_sets() {
    local scad_file="$1"
    local json_file="$2"

    mapfile -t PARAM_SETS < <(python3 -c "
import json, sys
with open('$json_file') as f:
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

        openscad -o "$out_stl" -p "$json_file" -P "$name" "$scad_file"

        # PNG preview: isometric-ish view from above, full render for headless compat
        openscad -o "$out_png" \
            --export-format png \
            --camera=0,0,0,60,0,30,500 \
            --autocenter --viewall \
            --imgsize=600,400 \
            --projection=perspective \
            --render \
            -p "$json_file" -P "$name" "$scad_file"
    done
}

export_param_sets "Roco_Kato_Adapter.scad"  "Roco_Kato_Adapter.json"
export_param_sets "tools/Roco_Sleeper_Belt.scad"  "tools/Roco_Sleeper_Belt.json"

echo "Done. STL files written to $OUT_DIR/, previews written to $IMG_DIR/"
