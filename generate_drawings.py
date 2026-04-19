#!/usr/bin/env python3
"""
generate_drawings.py — Annotated SVG track-plan drawings from layout SCAD files.

Reads  layouts/scad/*.scad
Writes layouts/drawings/{stem}.svg

Usage:
    python3 generate_drawings.py              # all layouts
    python3 generate_drawings.py foo.scad     # one or more specific files
"""

import sys, os, re, math, glob

# ── Physical constants (mm) ────────────────────────────────────────────────────
BED_HALF_W = 9.0    # half of 18 mm track bed width
MARGIN     = 30.0   # drawing margin (mm)
SCALE      = 3.5    # SVG pixels per mm

# ── Roco R1 correction ─────────────────────────────────────────────────────────
def eff_w(w, r):
    return 23.2 if (abs(w - 24) < 0.01 and abs(r - 194.6) < 0.1) else float(w)

def eff_r(w, r):
    return 200.0 if (abs(w - 24) < 0.01 and abs(r - 194.6) < 0.1) else float(r)

# ── SCAD parsing ───────────────────────────────────────────────────────────────
def strip_comments(text):
    text = re.sub(r'//[^\n]*', ' ', text)
    text = re.sub(r'/\*.*?\*/', ' ', text, flags=re.DOTALL)
    return text

def find_block_end(text, start):
    """Return index of ')' matching the '(' at text[start]."""
    depth = 0
    for i in range(start, len(text)):
        if   text[i] == '(': depth += 1
        elif text[i] == ')':
            depth -= 1
            if depth == 0:
                return i
    return len(text) - 1

def eval_val(s):
    s = s.strip().replace('true', 'True').replace('false', 'False')
    try:
        return eval(compile(s, '', 'eval'),
                    {'__builtins__': None, 'True': True, 'False': False}, {})
    except Exception:
        return s

def parse_args(block):
    """Extract {name: value} from a '(...)' block string."""
    inner = block[1:-1]
    args = {}
    for m in re.finditer(r'(\w+)\s*=\s*([^,)]+)', inner):
        args[m.group(1)] = eval_val(m.group(2))
    return args

def parse_layout_file(path):
    """
    Returns (title, pieces) where pieces is a list of
        {'label': str, 'frame': (x, y, hdg_deg), 'params': dict}
    """
    with open(path) as f:
        raw = f.read()

    title_m = re.search(r'//\s*title:\s*(.+)', raw)
    title = title_m.group(1).strip() if title_m else os.path.splitext(os.path.basename(path))[0]

    clean = strip_comments(raw)

    # Piece-label comments from original text
    piece_labels = []
    for m in re.finditer(r'//[^\n]*Piece\s+\d[^\n]*', raw):
        lbl = re.sub(r'^[/\s─\u2500\u2502\u2508]+', '', m.group(0)).strip()
        piece_labels.append((m.start(), lbl))

    # Tokenise all recognised calls
    CALL_RE = re.compile(r'\b(after_curved_exit|after_straight_exit|roco_adapter)\s*\(')
    tokens = []
    pos = 0
    while pos < len(clean):
        m = CALL_RE.search(clean, pos)
        if not m:
            break
        fn = m.group(1)
        bs = m.end() - 1                      # opening '('
        be = find_block_end(clean, bs)
        tokens.append((m.start(), fn, parse_args(clean[bs:be + 1])))
        pos = be + 1

    # Group transforms → roco_adapter into pieces
    pieces = []
    transforms = []
    for tpos, fn, args in tokens:
        if fn in ('after_curved_exit', 'after_straight_exit'):
            transforms.append((fn, args))
        elif fn == 'roco_adapter':
            label = ''
            for lpos, ltxt in piece_labels:
                if lpos < tpos:
                    label = ltxt
            frame = _compute_frame(transforms)
            transforms = []
            pieces.append({'label': label, 'frame': frame, 'params': args})

    return title, pieces

# ── Frame computation ──────────────────────────────────────────────────────────
def _curved_exit_delta(r, w, csl, cca, ccr, m):
    """(dx, dy, dangle) of the curved exit in the caller's local frame."""
    we, re_ = eff_w(w, r), eff_r(w, r)
    sign = -1 if m else 1
    dx = re_ * math.sin(math.radians(we))
    dy = sign * re_ * (1 - math.cos(math.radians(we)))
    angle = sign * we

    if csl > 0:
        rad = math.radians(angle)
        dx += csl * math.cos(rad)
        dy += csl * math.sin(rad)

    if cca > 0:
        ccwe, ccre_ = eff_w(cca, ccr), eff_r(cca, ccr)
        rad = math.radians(angle)
        lx =  ccre_ * math.sin(math.radians(ccwe))
        ly = -sign  * ccre_ * (1 - math.cos(math.radians(ccwe)))
        dx += lx * math.cos(rad) - ly * math.sin(rad)
        dy += lx * math.sin(rad) + ly * math.cos(rad)
        angle += -sign * ccwe

    return dx, dy, angle

def _apply_transform(frame, fn, args):
    x, y, hdg = frame
    if fn == 'after_straight_exit':
        sl  = float(args.get('sl', 0))
        rad = math.radians(hdg)
        return (x + sl * math.cos(rad), y + sl * math.sin(rad), hdg)
    elif fn == 'after_curved_exit':
        dx, dy, da = _curved_exit_delta(
            float(args.get('r',   194.6)),
            float(args.get('w',   24)),
            float(args.get('csl', 0)),
            float(args.get('cca', 0)),
            float(args.get('ccr', 194.6)),
            bool (args.get('m',   False)),
        )
        rad = math.radians(hdg)
        return (
            x + dx * math.cos(rad) - dy * math.sin(rad),
            y + dx * math.sin(rad) + dy * math.cos(rad),
            hdg + da,
        )
    return frame

def _compute_frame(transforms):
    frame = (0.0, 0.0, 0.0)
    for fn, args in transforms:
        frame = _apply_transform(frame, fn, args)
    return frame

# ── Path sampling (local frame, mm) ────────────────────────────────────────────
def _straight_pts(length):
    return [(0.0, 0.0), (length, 0.0)]

def _arc_pts(r, w, mirrored, step=1.0):
    """Centerline arc: entry at (0,0), heading +X."""
    we, re_ = eff_w(w, r), eff_r(w, r)
    n = max(4, int(we / step))
    sign = 1 if not mirrored else -1
    pts = []
    for i in range(n + 1):
        a = (i / n) * math.radians(we)
        pts.append((re_ * math.sin(a),
                    sign * re_ * (1 - math.cos(a))))
    return pts

def _s_curve_pts(r, w, cca, ccr, mirrored, step=1.0):
    """S-curve in local frame, starting at exit of main arc."""
    we,   re_  = eff_w(w,   r),   eff_r(w,   r)
    ccwe, ccre_ = eff_w(cca, ccr), eff_r(cca, ccr)
    sign = 1 if not mirrored else -1
    # Exit of main arc
    sx = re_ * math.sin(math.radians(we))
    sy = sign * re_ * (1 - math.cos(math.radians(we)))
    heading = math.radians(sign * we)
    cos_h, sin_h = math.cos(heading), math.sin(heading)

    n = max(4, int(ccwe / step))
    pts = []
    for i in range(n + 1):
        a  = (i / n) * math.radians(ccwe)
        lx =  ccre_ * math.sin(a)
        ly = -sign  * ccre_ * (1 - math.cos(a))
        pts.append((sx + lx * cos_h - ly * sin_h,
                    sy + lx * sin_h + ly * cos_h))
    return pts

def _transform_pts(pts, frame):
    px, py, hdg = frame
    rad = math.radians(hdg)
    cos_a, sin_a = math.cos(rad), math.sin(rad)
    return [(px + x * cos_a - y * sin_a,
             py + x * sin_a + y * cos_a) for x, y in pts]

# ── SVG helpers ────────────────────────────────────────────────────────────────
def _offset_line(pts, offset):
    """Offset a polyline by `offset` units (left of travel direction)."""
    result = []
    n = len(pts)
    for i in range(n):
        if i == 0:
            dx, dy = pts[1][0] - pts[0][0], pts[1][1] - pts[0][1]
        elif i == n - 1:
            dx, dy = pts[-1][0] - pts[-2][0], pts[-1][1] - pts[-2][1]
        else:
            dx, dy = pts[i+1][0] - pts[i-1][0], pts[i+1][1] - pts[i-1][1]
        L = math.hypot(dx, dy)
        if L < 1e-9:
            result.append(pts[i])
            continue
        nx, ny = -dy / L, dx / L
        result.append((pts[i][0] + offset * nx, pts[i][1] + offset * ny))
    return result

def _pts_to_str(pts):
    return ' '.join(f'{x:.1f},{y:.1f}' for x, y in pts)

def _midpoint(pts):
    i = len(pts) // 2
    return pts[i]

def _tangent_at_mid(pts):
    n = len(pts)
    i = n // 2
    a = pts[max(0, i-1)]
    b = pts[min(n-1, i+1)]
    dx, dy = b[0]-a[0], b[1]-a[1]
    L = math.hypot(dx, dy)
    return (dx/L, dy/L) if L > 1e-9 else (1, 0)

# ── Main drawing ───────────────────────────────────────────────────────────────
def draw_layout(title, pieces):
    # Collect all world-space segments for bounding-box calculation
    # segment = (world_pts, kind, annotation_text)
    all_segments = []   # (piece_idx, world_pts, kind, annotation)
    all_pts = []

    for pidx, piece in enumerate(pieces):
        frame = piece['frame']
        p = piece['params']

        sl  = float(p.get('straight_length',            0))
        ba  = float(p.get('branch_angle',               0))
        r   = float(p.get('radius',                194.6))
        csl = float(p.get('connecting_straight_length', 0))
        cca = float(p.get('connected_curve_angle',      0))
        ccr = float(p.get('connected_curve_radius', 194.6))
        m   = bool (p.get('mirrored',               False))

        if sl > 0:
            wp = _transform_pts(_straight_pts(sl), frame)
            all_pts.extend(wp)
            all_segments.append((pidx, wp, 'straight', f'{sl:.1f} mm'))

        if ba > 0:
            wp = _transform_pts(_arc_pts(r, ba, m), frame)
            all_pts.extend(wp)
            all_segments.append((pidx, wp, 'curve', f'R={r:.0f} mm, {ba:.0f}°'))

            if csl > 0:
                we_, re_ = eff_w(ba, r), eff_r(ba, r)
                sgn = 1 if not m else -1
                ex  = re_ * math.sin(math.radians(we_))
                ey  = sgn * re_ * (1 - math.cos(math.radians(we_)))
                hdg = sgn * we_
                rad = math.radians(hdg)
                lps = [(ex, ey), (ex + csl*math.cos(rad), ey + csl*math.sin(rad))]
                wp  = _transform_pts(lps, frame)
                all_pts.extend(wp)
                all_segments.append((pidx, wp, 'straight', f'{csl:.1f} mm'))

            if cca > 0:
                wp = _transform_pts(_s_curve_pts(r, ba, cca, ccr, m), frame)
                all_pts.extend(wp)
                all_segments.append((pidx, wp, 'curve', f'R={ccr:.0f} mm, {cca:.0f}°'))

    if not all_pts:
        return '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="100"><text x="10" y="50">No geometry</text></svg>'

    # Bounding box with bed width and margin
    xs = [pt[0] for pt in all_pts]
    ys = [pt[1] for pt in all_pts]
    min_x = min(xs) - BED_HALF_W - MARGIN
    max_x = max(xs) + BED_HALF_W + MARGIN
    min_y = min(ys) - BED_HALF_W - MARGIN
    max_y = max(ys) + BED_HALF_W + MARGIN

    # Reserve top margin for title (px)
    TITLE_H = 30
    W = (max_x - min_x) * SCALE
    H = (max_y - min_y) * SCALE + TITLE_H

    def to_svg(wx, wy):
        return ((wx - min_x) * SCALE,
                TITLE_H + (max_y - wy) * SCALE)   # Y-flip

    # Collect SVG elements (track beds first, then centerlines, then text)
    beds = []
    centres = []
    annotations = []

    # Piece colours (cycling through a small palette per piece)
    PALETTE = ['#c8d8e8', '#d8e8c8', '#e8d8c8', '#d8c8e8', '#e8e8c8', '#c8e8d8']

    for pidx, world_pts, kind, ann_text in all_segments:
        svg_pts = [to_svg(x, y) for x, y in world_pts]
        if len(svg_pts) < 2:
            continue

        fill = PALETTE[pidx % len(PALETTE)]
        left  = _offset_line(svg_pts, -BED_HALF_W * SCALE)
        right = _offset_line(svg_pts,  BED_HALF_W * SCALE)
        poly  = left + right[::-1]
        beds.append(f'<polygon points="{_pts_to_str(poly)}" '
                    f'fill="{fill}" stroke="#999" stroke-width="0.7"/>')

        centres.append(f'<polyline points="{_pts_to_str(svg_pts)}" '
                       f'fill="none" stroke="#cc2200" stroke-width="0.9" '
                       f'stroke-dasharray="5,3"/>')

        # Annotation: placed 20px in the normal-left direction from midpoint
        mid   = _midpoint(svg_pts)
        tx, ty = _tangent_at_mid(svg_pts)
        nx, ny = -ty, tx   # left normal in SVG space
        ax = mid[0] + nx * 18
        ay = mid[1] + ny * 18
        # White halo behind text
        annotations.append(
            f'<text x="{ax:.1f}" y="{ay:.1f}" font-size="9" font-family="sans-serif" '
            f'text-anchor="middle" fill="white" stroke="white" stroke-width="3" '
            f'paint-order="stroke">{ann_text}</text>')
        annotations.append(
            f'<text x="{ax:.1f}" y="{ay:.1f}" font-size="9" font-family="sans-serif" '
            f'text-anchor="middle" fill="#333">{ann_text}</text>')

    # Piece origin markers + labels
    markers = []
    for pidx, piece in enumerate(pieces):
        ox, oy = to_svg(*piece['frame'][:2])
        lbl = piece['label'] or f'Piece {pidx+1}'
        # Trim clutter: strip long dashes
        lbl = re.sub(r'\s*─+\s*$', '', lbl).strip()
        markers.append(
            f'<circle cx="{ox:.1f}" cy="{oy:.1f}" r="4" fill="#336699" opacity="0.85"/>')
        markers.append(
            f'<text x="{ox+6:.1f}" y="{oy-5:.1f}" font-size="8" font-family="sans-serif" '
            f'fill="#336699" text-anchor="start" font-weight="bold">{lbl}</text>')

    # Scale bar (50 mm)
    bar_x1 = MARGIN * SCALE * 0.5
    bar_x2 = bar_x1 + 50 * SCALE
    bar_y  = H - MARGIN * SCALE * 0.5
    scalebar = [
        f'<line x1="{bar_x1:.1f}" y1="{bar_y:.1f}" x2="{bar_x2:.1f}" y2="{bar_y:.1f}" stroke="#333" stroke-width="1.5"/>',
        f'<line x1="{bar_x1:.1f}" y1="{bar_y-4:.1f}" x2="{bar_x1:.1f}" y2="{bar_y+4:.1f}" stroke="#333" stroke-width="1.5"/>',
        f'<line x1="{bar_x2:.1f}" y1="{bar_y-4:.1f}" x2="{bar_x2:.1f}" y2="{bar_y+4:.1f}" stroke="#333" stroke-width="1.5"/>',
        f'<text x="{(bar_x1+bar_x2)/2:.1f}" y="{bar_y+16:.1f}" font-size="9" font-family="sans-serif" '
        f'text-anchor="middle" fill="#333">50 mm</text>',
    ]

    # Overall bounding box dimensions
    w_mm = max(xs) - min(xs)
    h_mm = max(ys) - min(ys)
    bbox_note = (f'<text x="{W:.1f}" y="{H:.1f}" font-size="8" font-family="sans-serif" '
                 f'fill="#888" text-anchor="end">'
                 f'span: {w_mm:.0f} × {h_mm:.0f} mm</text>')

    # Assemble SVG
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W:.0f}" height="{H:.0f}" '
        f'viewBox="0 0 {W:.0f} {H:.0f}">',
        f'<title>{title}</title>',
        '<rect width="100%" height="100%" fill="white"/>',
        # Title
        f'<text x="{W/2:.1f}" y="20" font-size="14" font-family="sans-serif" '
        f'font-weight="bold" text-anchor="middle" fill="#222">{title}</text>',
    ]
    parts += beds
    parts += centres
    parts += annotations
    parts += markers
    parts += scalebar
    parts.append(bbox_note)
    parts.append('</svg>')
    return '\n'.join(parts)

# ── Entry point ────────────────────────────────────────────────────────────────
def main():
    repo = os.path.dirname(os.path.abspath(__file__))
    scad_dir = os.path.join(repo, 'layouts', 'scad')
    out_dir  = os.path.join(repo, 'layouts', 'drawings')
    os.makedirs(out_dir, exist_ok=True)

    files = sys.argv[1:] if len(sys.argv) > 1 else sorted(glob.glob(os.path.join(scad_dir, '*.scad')))

    for f in files:
        stem = os.path.splitext(os.path.basename(f))[0]
        print(f'Drawing: {stem}')
        try:
            title, pieces = parse_layout_file(f)
            svg = draw_layout(title, pieces)
            out = os.path.join(out_dir, f'{stem}.svg')
            with open(out, 'w') as fp:
                fp.write(svg)
            print(f'  → {out}')
        except Exception as e:
            import traceback
            print(f'  ERROR: {e}')
            traceback.print_exc()

if __name__ == '__main__':
    main()
