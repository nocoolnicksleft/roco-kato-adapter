// title: Curved Turnout Left
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
include <../../Roco_Kato_Adapter.scad>

// ── Piece 1: Roco Turnout R 2418 (right/mirrored) ────────────────────────────





// ── Piece 2: Roco Curve 2420 R1 24° - curved exit of piece 1 ──────────────

    roco_adapter(
            connecting_straight_length = 0,
            drive_length = 0,
            enable_entrance_unijoiner = false,
            enable_exit_unijoiner_straight = true,
            straight_length = 0,
            radius = 356.5,
            branch_angle = 45,
            mirrored = false
    );

        roco_adapter(
            connecting_straight_length = 0,
            drive_length = 0,
            drive_offset = 10,
            drive_width = 10,
            enable_entrance_unijoiner = true,
            straight_length = 0,
            radius = 420,
            branch_angle = 45,
            mirrored = false
        );


  