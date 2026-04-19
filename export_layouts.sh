#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SCAD_DIR="$REPO_ROOT/layouts/scad"
STL_DIR="$REPO_ROOT/layouts/stl"
IMG_DIR="$REPO_ROOT/layouts/img"
OVERVIEW="$REPO_ROOT/layouts/overview.md"

mkdir -p "$STL_DIR" "$IMG_DIR"

md_rows=()

for scad_file in "$SCAD_DIR"/*.scad; do
    stem="$(basename "$scad_file" .scad)"

    # Extract optional '// title: ...' line from file, else use the stem as-is
    title=$(grep -m1 '^\s*//\s*title:' "$scad_file" 2>/dev/null \
            | sed 's|.*//\s*title:\s*||' \
            || true)
    [[ -z "$title" ]] && title="$stem"

    out_stl="$STL_DIR/${stem}.stl"
    out_png="$IMG_DIR/${stem}.png"

    echo "Exporting layout: $stem"

    # STL
    openscad -o "$out_stl" "$scad_file"

    # PNG thumbnail
    openscad -o "$out_png" \
        --export-format png \
        --camera=0,0,0,60,0,30,500 \
        --autocenter --viewall \
        --imgsize=600,400 \
        --projection=perspective \
        "$scad_file"

    md_rows+=("| [$title](scad/${stem}.scad) | ![${stem}](img/${stem}.png) |")
done

# Write overview.md
{
    echo "# Layout Overview"
    echo ""
    echo "| Layout | Preview |"
    echo "|--------|---------|"
    for row in "${md_rows[@]}"; do
        echo "$row"
    done
} > "$OVERVIEW"

echo "Done."
echo "  STL:      layouts/stl/"
echo "  Images:   layouts/img/"
echo "  Overview: layouts/overview.md"

# Generate annotated SVG drawings
echo "Generating SVG drawings..."
python3 "$REPO_ROOT/generate_drawings.py"
echo "  Drawings: layouts/drawings/"
