/*
    Angled_Platform_Pillars.scad
    ────────────────────────────
    A row of rectangular-section pillars with sloped tops for carrying an
    inclined platform.  All pillars lie under the same inclined plane, so the
    slope on every top face is identical.

    Coordinate system
    ─────────────────
    Pillar row runs along +X (slope direction).
    Each pillar is pillar_length (X) × pillar_width (Y).
    Bottom of every pillar at Z = 0.
    The pillar tops support a board whose underside is at height_start at X = 0
    and at height_end at X = board_length.
    The real-world spacing between pillars on the layout is derived
    automatically so that the pillars are evenly distributed across the full
    board_length:

      layout_gap = (board_length − num_pillars × pillar_length) / (num_pillars − 1)

    print_gap controls the clear space between adjacent rims in the printed
    model only and does not affect the slope calculation.

    Slope definition
    ────────────────
    The slope is specified in terms of the board sitting on the pillars:
      board_length  – horizontal distance over which the height changes
      height_start  – board height at X = 0   (underside of board / pillar top)
      height_end    – board height at X = board_length

      slope_angle = atan((height_end − height_start) / board_length)

    This angle is the same for every pillar top face and is echoed to the
    console on render.  It is NOT a free parameter.

    Rim
    ───
    Each pillar stands on a flat rim (flange) that extends rim_width mm beyond
    the pillar on all four sides and is 2 mm tall.  This prevents toppling
    during installation.  In the printed model the gap between adjacent rims
    is print_gap mm.

    Gauge strip
    ───────────
    When show_gauge = true, (num_pillars − 1) flat strips are rendered, one
    per inter-pillar gap.  Each strip is exactly layout_gap long, 15 mm wide,
    and 2 mm tall — use one as a positioning aid when placing pillars on the
    layout.  Strips are placed behind the pillar row (offset in Y).

    Track indent
    ────────────
    When show_track_indent = true, a shallow channel (1.5 mm deep, 26 mm wide,
    full pillar_length in X) is cut into the sloped top face, centred in Y.
    This cradles the Kato track for test-fitting on the pillar.

    Parameters
    ──────────
    num_pillars         Number of pillars in the row.
    pillar_length       Pillar dimension along the slope direction (X) in mm.
    pillar_width        Pillar dimension across the slope direction (Y) in mm.
    rim_width           Rim overhang beyond the pillar on each side in mm.
    print_gap           Clear space between adjacent rims in the printed model
                        (mm ≥ 1).  Does not affect slope.
    board_length        Horizontal span over which the slope is measured (mm).
    height_start        Height of the board's underside at X = 0 (mm).
    height_end          Height of the board's underside at X = board_length (mm).
    show_gauge          true = include spacing gauge strips in the render.
    show_track_indent   true = cut a Kato-track cradle into each sloped top.
*/

/* [Pillars] */
// Number of pillars
num_pillars = 6;

// Pillar dimension along the slope direction (X) in mm
pillar_length = 30; // [1:0.5:100]

// Pillar dimension across the slope direction (Y) in mm
pillar_width = 40; // [1:0.5:100]

// Rim overhang beyond the pillar on each side in mm
rim_width = 15; // [0:0.5:30]

// Clear space between adjacent rims in the printed model in mm
print_gap = 1; // [1:0.5:20]

/* [Board / Slope] */
// Horizontal distance over which the board height changes in mm
board_length = 800; // [1:1:2000]

// Height of the board's underside at the start of the row (X = 0) in mm
height_start = 30; // [0:0.5:200]

// Height of the board's underside at the end of board_length in mm
height_end = 90; // [0:0.5:200]

/* [Gauge] */
// Include spacing gauge strips for layout positioning
show_gauge = true;

// Cut a Kato-track cradle (1.5 mm deep, 26 mm wide) into each sloped top
show_track_indent = false;

/* [Hidden] */
$fn = 32;
_rim_h = 2;        // fixed rim height in mm
_indent_depth = 1.5; // track indent depth in mm
_indent_width = 26;  // Kato track width in mm

// ── Single pillar with sloped top ─────────────────────────────────────────────
//   Low-side bottom corner at origin.  pl = length (X), pw = width (Y).
module _sloped_pillar(pl, pw, h_lo, h_hi) {
    polyhedron(
        points = [
            [0,  0,  0   ], // 0  front-low  (bottom)
            [pl, 0,  0   ], // 1  front-high (bottom)
            [pl, pw, 0   ], // 2  back-high  (bottom)
            [0,  pw, 0   ], // 3  back-low   (bottom)
            [0,  0,  h_lo], // 4  front-low  (top)
            [pl, 0,  h_hi], // 5  front-high (top)
            [pl, pw, h_hi], // 6  back-high  (top)
            [0,  pw, h_lo], // 7  back-low   (top)
        ],
        faces = [
            [0, 3, 2, 1], // bottom
            [4, 5, 6, 7], // top (sloped)
            [0, 1, 5, 4], // front (−Y)
            [1, 2, 6, 5], // right (+X, high side)
            [2, 3, 7, 6], // back  (+Y)
            [3, 0, 4, 7], // left  (−X, low side)
        ]
    );
}

// ── Track indent cutter ───────────────────────────────────────────────────────
//   Sloped polyhedron matching the top face, used in difference() to carve a
//   channel centred in Y. eps pushes the cutter just above the surface.
module _track_indent_cut(pl, pw, h_lo, h_hi, depth, width) {
    eps = 0.01;
    y0  = (pw - width) / 2;
    y1  = (pw + width) / 2;
    polyhedron(
        points = [
            [0,  y0, h_lo - depth], // 0
            [pl, y0, h_hi - depth], // 1
            [pl, y1, h_hi - depth], // 2
            [0,  y1, h_lo - depth], // 3
            [0,  y0, h_lo + eps  ], // 4
            [pl, y0, h_hi + eps  ], // 5
            [pl, y1, h_hi + eps  ], // 6
            [0,  y1, h_lo + eps  ], // 7
        ],
        faces = [
            [0, 3, 2, 1],
            [4, 5, 6, 7],
            [0, 1, 5, 4],
            [1, 2, 6, 5],
            [2, 3, 7, 6],
            [3, 0, 4, 7],
        ]
    );
}

// ── Row of angled-platform pillars ────────────────────────────────────────────
module angled_platform_pillars(
    num_pillars,
    pillar_length,
    pillar_width,
    rim_width         = 15,
    print_gap         = 1,
    board_length      = 800,
    height_start      = 30,
    height_end        = 90,
    show_gauge        = true,
    show_track_indent = false
) {
    pl  = pillar_length;
    pw  = pillar_width;
    rw  = rim_width;
    n   = num_pillars;
    pg  = print_gap;
    bl  = board_length;
    hs  = height_start;
    he  = height_end;

    // Layout gap: evenly distribute pillar bodies across board_length
    lg = (bl - n * pl) / (n - 1);

    // Slope rate: height gained per mm of horizontal travel
    slope = (he - hs) / bl;

    // Unit pitch in the printed model: rim + pillar + rim + gap
    unit_w = pl + 2 * rw + pg;

    // Informational echoes
    echo(str("slope_angle     = ", atan(slope), "°"));
    echo(str("layout_gap      = ", lg, " mm"));
    echo(str("print_row_span  = ", n * (pl + 2*rw) + (n-1) * pg, " mm"));

    // ── Pillars ──────────────────────────────────────────────────────────────
    for (i = [0 : n - 1]) {
        // Layout X positions → determine heights
        layout_x_lo = i * (pl + lg);
        layout_x_hi = layout_x_lo + pl;
        h_lo = hs + layout_x_lo * slope;
        h_hi = hs + layout_x_hi * slope;

        // Each unit origin is at the rim's low-X, low-Y corner
        translate([i * unit_w, 0, 0]) {
            // Rim (flat flange around the base)
            cube([pl + 2*rw, pw + 2*rw, _rim_h]);
            // Pillar body, offset so rim extends rw on all sides
            translate([rw, rw, 0])
                if (show_track_indent)
                    difference() {
                        _sloped_pillar(pl, pw, h_lo, h_hi);
                        _track_indent_cut(pl, pw, h_lo, h_hi,
                                          _indent_depth, _indent_width);
                    }
                else
                    _sloped_pillar(pl, pw, h_lo, h_hi);
        }
    }

    // ── Gauge strip (optional) ───────────────────────────────────────────────────────────────────────────────────────
    //   A single strip exactly layout_gap × 15 × 2 mm — all gaps are equal so
    //   one is enough.  Placed behind the pillar row (Y offset = pw + 2*rw + pg).
    if (show_gauge)
        translate([0, pw + 2*rw + pg, 0])
            cube([lg, 15, 2]);
}

// ── Render ────────────────────────────────────────────────────────────────────
angled_platform_pillars(
    num_pillars,
    pillar_length,
    pillar_width,
    rim_width,
    print_gap,
    board_length,
    height_start,
    height_end,
    show_gauge,
    show_track_indent
);
