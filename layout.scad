/*
    layout.scad - Multi-piece layout plate.

    Diagram (curved exits branch away from the straight axis):

        [1: Right turnout 2418]
               │ (curved exit, -Y direction since mirrored)
        [2: 33.6mm straight]
               │
        [3: Left turnout 2417]
               │ (curved exit, +Y in local frame)
        [4: 33.6mm straight]

    Positioning rules:
      - after_straight_exit(sl) : step forward sl mm along the current +X axis
      - after_curved_exit(r, w, csl, cca, m) : jump to the curved exit of the
        preceding piece, matching its exit direction
      - Nest calls to chain: each outer call sets the frame for the inner ones.
      - At every joint between two pieces, disable the unijoiner on BOTH sides:
        the exit unijoiner of the upstream piece and the entrance unijoiner of
        the downstream piece.  Because the pieces are printed as one merged
        object, no physical unijoiner connector is needed there.
*/

layout_mode = true;      // suppresses the single-piece preview render
include <Roco_Kato_Adapter.scad>

// ── Piece 1: Roco Turnout R 2418 (right/mirrored) ────────────────────────────

roco_adapter(
    straight_length             = 104.2,
    branch_angle                = 24,
    radius                      = 194.6,
    connecting_straight_length  = 0,
    connected_curve_angle       = 0,
    drive_length                = 90,
    drive_width                 = 10,
    drive_offset                = 6,
    drive_inset                 = 4,
    drive_cableslot_diameter    = 4,
    drive_cableslot_offset      = 80,
    enable_entrance_unijoiner       = true,
    enable_exit_unijoiner_straight  = true,
    enable_exit_unijoiner_curved    = false,  // joins piece 2
    mirrored                    = true
);

// ── Piece 2: Roco Straight 2413 33.6mm - curved exit of piece 1 ──────────────

after_curved_exit(r = 194.6, w = 24, csl = 0, cca = 0, m = true)
    roco_adapter(
        straight_length             = 33.6,
        branch_angle                = 0,
        connecting_straight_length  = 0,
        drive_length                = 0,
        enable_entrance_unijoiner       = false,  // joins piece 1
        enable_exit_unijoiner_straight  = false,  // joins piece 3
        enable_exit_unijoiner_curved    = false,
        mirrored                    = false
    );

// ── Piece 3: Roco Turnout L 2417 - after piece 2 ─────────────────────────────

after_curved_exit(r = 194.6, w = 24, csl = 0, cca = 0, m = true)
after_straight_exit(sl = 33.6)
    roco_adapter(
        straight_length             = 104.2,
        branch_angle                = 24,
        radius                      = 194.6,
        connecting_straight_length  = 0,
        connected_curve_angle       = 0,
        drive_length                = 90,
        drive_width                 = 10,
        drive_offset                = 6,
        drive_inset                 = 4,
        drive_cableslot_diameter    = 4,
        drive_cableslot_offset      = 80,
        enable_entrance_unijoiner       = false,  // joins piece 2
        enable_exit_unijoiner_straight  = true,
        enable_exit_unijoiner_curved    = false,  // joins piece 4
        mirrored                    = false
    );

// ── Piece 4: Roco Straight 2413 33.6mm - curved exit of piece 3 ──────────────

after_curved_exit(r = 194.6, w = 24, csl = 0, cca = 0, m = true)
after_straight_exit(sl = 33.6)
after_curved_exit(r = 194.6, w = 24, csl = 0, cca = 0, m = false)
    roco_adapter(
        straight_length             = 33.6,
        branch_angle                = 0,
        connecting_straight_length  = 0,
        drive_length                = 0,
        enable_entrance_unijoiner       = false,  // joins piece 3
        enable_exit_unijoiner_straight  = true,
        enable_exit_unijoiner_curved    = false,
        mirrored                    = false
    );
