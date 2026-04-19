/*
    Roco_Sleeper_Belt.scad
    ──────────────────────
    A continuous belt of individual Roco N-scale sleepers, either straight or
    curved. Intended as a filler strip to be glued beneath a Roco track section
    that sits on a Kato Unitrack layout where no adapter bed geometry is needed.

    Coordinate system
    ─────────────────
    Entry at origin, travel direction along +X.
    Curved belt arcs toward +Y (same convention as all other modules here).
    Bottom of sleepers at Z = 0.

    Parameters
    ──────────
    n_sleepers  Number of sleepers in the belt.
    diameter    Circle diameter of the track centreline in mm.
                0 = straight belt.
                Matches the Roco/Kato radii used in Roco_Kato_Adapter.scad:
                  R1 = 389.2  (radius 194.6)
                  R2 = 456.4  (radius 228.2)
                  R3 = 523.6  (radius 261.8)
                  R3A= 590.8  (radius 295.4)
                  R4 = 658.0  (radius 329.0)
                  R5 = 725.2  (radius 362.6)
                  R6 = 960.0  (radius 480.0)
    end_start   End type at entry:
    end_finish  End type at exit:
                  "Closed"    belt ends with a full sleeper (default)
                  "Open"      rail blocks extend one pitch beyond the last
                              sleeper — open stub to butt against the next piece
                  "Unijoiner" right (+Y) rail block trimmed back 2 pitches;
                              those 2 sleepers are half-width (−Y half only)
    "Right rail" = +Y side (Kato Unijoiner plug side).
*/

/* [Belt] */
// Number of sleepers
n_sleepers = 20;

// Track-centreline circle diameter in mm (0 = straight)
diameter = 389.2; // [0, 389.2, 456.4, 523.6, 590.8, 658.0, 725.2, 960.0]

// End type at the start of the belt (entry)
end_start  = "Closed"; // ["Closed", "Open", "Unijoiner"]

// End type at the finish of the belt (exit)
end_finish = "Closed"; // ["Closed", "Open", "Unijoiner"]

/* [Hidden] */
// ── Sleeper dimensions ────────────────────────────────────────────────────────
_sl_w     = 16.0;   // sleeper width (across track, Y)
_sl_h     =  1.8;   // sleeper height (Z)
_sl_t     =  1.7;   // sleeper thickness (travel direction); also rail-block cross-section width
_sl_pitch =  4.9;   // centre-to-centre spacing in mm

// N scale track gauge (rail centre-to-centre distance)
// Nominal NEM is 9.0 mm; Roco N track measures ~9.5 mm
_n_gauge  =  9.5;

// Rail clamp dimensions (cube) and distance from rail centreline to clamp centre
_clamp_s   = 1.3;   // clamp cube side length
_clamp_gap = 1.27;   // centre of clamp to centre of rail (straddles rail foot)

// ── Full sleeper, centred on X=0, Y=0, bottom at Z=0 ────────────────────────
module _one_sleeper() {
    translate([-_sl_t / 2, -_sl_w / 2, 0])
        cube([_sl_t, _sl_w, _sl_h]);
}

// ── Half sleeper, centred on X=0, Y=0, bottom at Z=0 ────────────────────────
//   neg_y=true  → keeps −Y half, omits +Y  (right when looking centre→start)
//   neg_y=false → keeps +Y half, omits −Y  (right when looking centre→finish)
module _half_sleeper(neg_y = true) {
    translate([-_sl_t / 2, neg_y ? -_sl_w / 2 : 0, 0])
        cube([_sl_t, _sl_w / 2, _sl_h]);
}

// ── Rail clamps for one sleeper (local frame, same origin as _one_sleeper) ───
//   Two clamps per rail (one each Y-side), sitting on top of the sleeper.
//   left_ok / right_ok: pass false to suppress clamps on that rail.
module _rail_clamps_on_sleeper(left_ok = true, right_ok = true) {
    for (rail = [[-_n_gauge / 2, false], [_n_gauge / 2, true]]) {
        rail_y   = rail[0];
        is_right = rail[1];
        if ((is_right && right_ok) || (!is_right && left_ok))
            for (side = [-1, 1])
                translate([
                    -_clamp_s / 2,
                    rail_y + side * _clamp_gap - _clamp_s / 2,
                    _sl_h
                ])
                    cube([_clamp_s, _clamp_s, _clamp_s]);
    }
}

// ── Longitudinal rail blocks ──────────────────────────────────────────────────
//   One block per rail.  End types adjust each block independently:
//     "Open"      extends by one pitch at the relevant end (both rails)
//     "Unijoiner" trims the right (+Y) rail by 2 pitches at the relevant end
//     "Closed"    default — block spans first to last sleeper
module _rail_blocks(n, diameter, es, ef) {
    r = diameter / 2;

    for (rail = [[-_n_gauge / 2, false], [_n_gauge / 2, true]]) {
        dy       = rail[0];
        is_right = rail[1];
        // In curved mode the +Y rail sits at r − gauge/2 (inner side of +Y arc)
        dr = is_right ? -_n_gauge / 2 : _n_gauge / 2;

        // Start adjustment: negative = extend before start; positive = trim from start
        // Unijoiner at start omits the right (+Y) rail → trim is_right block
        se = es == "Open"                  ? -_sl_pitch :
             es == "Unijoiner" && is_right ?  2 * _sl_pitch : 0;
        // End adjustment: positive = extend past end; negative = trim from end
        // Unijoiner at finish omits the right rail when looking centre→finish,
        // which is the −Y (left) rail in global coords → trim !is_right block
        ee = ef == "Open"                   ?  _sl_pitch :
             ef == "Unijoiner" && !is_right ? -2 * _sl_pitch : 0;

        if (diameter == 0) {
            x_start = -_sl_t / 2 + se;
            x_end   = (n - 1) * _sl_pitch + _sl_t / 2 + ee;
            if (x_end > x_start)
                translate([x_start, dy - _sl_t / 2, 0])
                    cube([x_end - x_start, _sl_t, _sl_h]);
        } else {
            // rotate_extrude: outer rotate([0,0,-90+start_shift]) shifts the arc
            // start angle; sweep covers the adjusted span.
            // Math: rotate by (-90+δ) maps extrusion angle α to belt arc angle (α+δ).
            deg_pp      = _sl_pitch / r * (180 / PI);
            start_shift = es == "Open"                  ? -deg_pp :
                          es == "Unijoiner" && is_right ?  2 * deg_pp : 0;
            end_shift   = ef == "Open"                  ?  deg_pp :
                          ef == "Unijoiner" && is_right ? -2 * deg_pp : 0;
            sweep = (n - 1) * deg_pp - start_shift + end_shift;
            if (sweep > 0)
                translate([0, r, 0])
                rotate([0, 0, -90 + start_shift])
                rotate_extrude(angle = sweep, $fn = 360)
                    translate([r + dr - _sl_t / 2, 0])
                        square([_sl_t, _sl_h]);
        }
    }
}

// ── Sleeper belt ─────────────────────────────────────────────────────────────
//   n        : number of sleepers
//   diameter : track-centreline circle diameter in mm; 0 = straight
//   es       : end type at start  ("Closed" / "Open" / "Unijoiner")
//   ef       : end type at finish ("Closed" / "Open" / "Unijoiner")
module sleeper_belt(n = 20, diameter = 0, es = "Closed", ef = "Closed") {
    r = diameter / 2;

    union() {
        // Individual sleepers + clamps
        if (diameter == 0) {
            for (i = [0 : n - 1]) {
                s_half = es == "Unijoiner" && i < 2;       // start-end half (omit +Y)
                f_half = ef == "Unijoiner" && i >= n - 2;  // finish-end half (omit −Y)
                half   = s_half || f_half;
                translate([i * _sl_pitch, 0, 0]) {
                    if (half) _half_sleeper(neg_y = s_half); else _one_sleeper();
                    _rail_clamps_on_sleeper(left_ok = !f_half, right_ok = !s_half);
                }
            }
        } else {
            deg_per_pitch = _sl_pitch / r * (180 / PI);
            for (i = [0 : n - 1]) {
                s_half = es == "Unijoiner" && i < 2;
                f_half = ef == "Unijoiner" && i >= n - 2;
                half   = s_half || f_half;
                a = i * deg_per_pitch;
                translate([r * sin(a), r * (1 - cos(a)), 0])
                rotate([0, 0, a]) {
                    if (half) _half_sleeper(neg_y = s_half); else _one_sleeper();
                    _rail_clamps_on_sleeper(left_ok = !f_half, right_ok = !s_half);
                }
            }
        }

        // Connecting rail blocks (handles all end types)
        _rail_blocks(n, diameter, es, ef);

        // Centre-line connecting belt at each Unijoiner end
        _center_connecting_belts(n, diameter, es, ef);
    }
}

// ── Centre connecting belt at Unijoiner ends ──────────────────────────────────
//   A _sl_t-wide strip running along the track centreline (Y=0) over the two
//   half-sleeper positions and reaching the first full sleeper, to provide
//   structural continuity where the rail block is absent.
module _center_connecting_belts(n, diameter, es, ef) {
    r = diameter / 2;

    if (diameter == 0) {
        if (es == "Unijoiner") {
            // spans sleepers 0, 1 (half) and reaches sleeper 2 (first full)
            x0 = -_sl_t / 2;
            x1 =  2 * _sl_pitch + _sl_t / 2;
            translate([x0, -_sl_t / 2, 0])
                cube([x1 - x0, _sl_t, _sl_h]);
        }
        if (ef == "Unijoiner") {
            // spans last full sleeper (n-3) and the two half sleepers (n-2, n-1)
            x0 = (n - 3) * _sl_pitch - _sl_t / 2;
            x1 = (n - 1) * _sl_pitch + _sl_t / 2;
            translate([x0, -_sl_t / 2, 0])
                cube([x1 - x0, _sl_t, _sl_h]);
        }
    } else {
        deg_pp = _sl_pitch / r * (180 / PI);
        half_t_deg = (_sl_t / 2) / r * (180 / PI);

        if (es == "Unijoiner") {
            a0    = -half_t_deg;
            sweep = 2 * deg_pp + 2 * half_t_deg;
            translate([0, r, 0])
            rotate([0, 0, -90 + a0])
            rotate_extrude(angle = sweep, $fn = 360)
                translate([r - _sl_t / 2, 0])
                    square([_sl_t, _sl_h]);
        }
        if (ef == "Unijoiner") {
            a0    = (n - 3) * deg_pp - half_t_deg;
            sweep = 2 * deg_pp + 2 * half_t_deg;
            translate([0, r, 0])
            rotate([0, 0, -90 + a0])
            rotate_extrude(angle = sweep, $fn = 360)
                translate([r - _sl_t / 2, 0])
                    square([_sl_t, _sl_h]);
        }
    }
}

// ── Preview ──────────────────────────────────────────────────────────────────
sleeper_belt(n = n_sleepers, diameter = diameter, es = end_start, ef = end_finish);
