

// Length of the straight entry section, 0 to omit
straight_length = 104.2;      

// Branch angle of the turnout curve, 0 for straight track only
branch_angle = 24;         // [0, 6, 15, 24, 30]

// Radius of the turnout curve
radius = 194.6;   // [194.6, 228.2, 261.8, 295.4, 329.0, 362.6, 480]

// Straight section appended to end of branch curve, 0 to omit
connecting_straight_length = 0;

// S-curve angle appended after branch curve (to make exits parallel), 0 to omit
connected_curve_angle = 0; // [0, 6, 15, 24, 30]

// S-curve radius
connected_curve_radius = 194.6; // [194.6, 228.2, 261.8, 295.4, 329.0, 362.6, 480]

/* [Drive Platform] */
// Length of drive platform (point motor mount), 0 to omit
drive_length = 0; // 89 for turnout drive in Roco 2417

// Width of drive platform
drive_width = 10.0; // 10 for turnout drive in Roco 2417

// Offset of drive platform from entry
drive_offset = 6; // 6 for turnout drive in Roco 2417

// Width of the recessed area at the end of the platform
drive_inset = 4; // 4 for turnout drive in Roco 2417

// Diameter of cable slot/hole
drive_cableslot_diameter = 4;

// Offset of the cable slot/hole
drive_cableslot_offset = 80;

/* [Options] */
// Generate Unijoiner at entrance end(s)
enable_entrance_unijoiner = true;

// Generate Unijoiner at straight end
enable_exit_unijoiner_straight = true;

// Generate Unijoiner at curved end
enable_exit_unijoiner_curved = true;

// Add small cylindrical rims around the unijoiner receptacles. Needed for firm connection with original Unitrack. Switch off for better fit with 3D-printed Unitrack
enable_rims = true; 

// Render mirrored over Y axis (right-hand turnout)
mirrored = true;

module endofparms() {
    
}
/*
    Remarks:
    This is a model railway adapter toolkit. The resulting object is intended to be printed and glued to the 
    bottom of a rail segments of N size tracks (Roco, Minitrix and others) to adapt it to the Kato Unitrack system. The model is designed to be as flexible as possible, 
    so that it can be used for different turnouts and configurations. The parameters at the top of the file allow you 
    to customize the adapter for your specific needs.

    The target system is the Kato Unitrack, which has a sleeper bed that is 127mm wide. 
    Parts are joined using Unijoiners, which are small plastic connectors that fit into slots in the sleeper bed. 
    Unijoiners consist of a plug on the right side and a receptacle on the left side when looking from the front of the track.
    This is independent of direction and mirrored state.

    --- Coordinate system ---
    The track entry is at the origin; the track runs along +X.
    The non-mirrored turnout curve branches toward +Y; mirrored branches toward -Y.

    Turnout curve endpoint P1 (w = branch_angle, r = radius):
        non-mirrored:  P1 = ( r*sin(w),  r*(1-cos(w)), 0 ),  exit direction = rotate([0,0, w])
        mirrored:      P1 = ( r*sin(w), -r*(1-cos(w)), 0 ),  exit direction = rotate([0,0,-w])

    S-curve (connected_curve) endpoint in the local frame at P1
    (ccr = connected_curve_radius, cca = connected_curve_angle):
        non-mirrored:  delta = ( ccr*sin(cca), -ccr*(1-cos(cca)), 0 ),  exit direction = rotate([0,0,-cca])
        mirrored:      delta = ( ccr*sin(cca), +ccr*(1-cos(cca)), 0 ),  exit direction = rotate([0,0,+cca])

    --- Mirroring rule for all exit unijoiners ---
    To place a unijoiner at a mirrored exit, negate the Y component of every translation
    and negate every rotation angle, compared to the non-mirrored form.
    Do NOT use mirror([0,1,0]) around the unijoiner call: that flips the shape's
    internal left/right geometry, reversing plug and receptacle sides.
    Do NOT use rotate([0,0,180]) with negative-angle trig: that produces the wrong
    position and requires hard-coded magic offsets to compensate.

    --- Unijoiner orientation ---
    Plug on the RIGHT, receptacle on the LEFT, when looking at the connector from the front.
    This rule holds regardless of mirrored state or travel direction.
    The unijoiner_receptable(reverse) parameter and the legacy _rev modules
    are not needed for mirrored exits when the above coordinate approach is used.
*/
include <Kato.scad>;



module drive_box(reverse, drive_length, drive_width, drive_inset, drive_cableslot_diameter, drive_cableslot_offset) {
        inset_height = 1;
        $fn=360;

        difference() {
            cube([drive_length, drive_width, bed_height]);
            if (drive_inset > 0) {
                translate([0, reverse ? drive_width - drive_inset : 0,bed_height-recess_depth-inset_height])
                    cube([drive_length, drive_inset, inset_height]);
            }
            translate([drive_cableslot_offset,reverse ? drive_width - 3 : 3,0])
                cylinder(d = drive_cableslot_diameter, h = bed_height);
        }
        
}

module drive_cut(drive_length, drive_width) {
    // Width plus two to eliminate the rim of the bed
    cube([drive_length, drive_width + 2, bed_height]);
}

module unijoiner_receptable_rev() {
    slotwidth = 3;
    translate([0, bed_width_top/4 - unijoiner_width/2 - 0.4, 0])    
    hull() {
        cube([unijoiner_depth + 1, unijoiner_width + 0.2, 2.5]);
        translate([0,unijoiner_width / 2 - slotwidth / 2 ,0]) 
            cube([unijoiner_depth + 1, slotwidth, bed_height - recess_depth]); 
    }
}

/*
    --- Physical calibration corrections ---

    The nominal Roco track geometry (as published in catalogues and commonly cited
    on model railway forums) does not exactly match the physical dimensions of the
    manufactured track.  When a straight adapter printed with the nominal values is
    inserted into the curved exit of a turnout adapter, the slight angular mismatch
    causes the real track to bow outward.  Forcing it flat opens the rail contact
    spring — enough to cause electrical dropouts and derailments.

    The discrepancy was determined by measuring the lateral offset of the curved
    branch exit of a Roco 2417/2418 R1 turnout from its straight axis:

        Nominal:  r · (1 − cos w) = 194.6 · (1 − cos 24°) ≈ 16.82 mm
        Measured: ≈ 16.2 mm

    Solving for a corrected angle from the measured offset alone gives w ≈ 23.54°,
    but that also shortens the X-projection of the curve (r·sin w), making the
    overall compound plate too short.  The correct approach is to satisfy both the
    lateral offset and the longitudinal projection simultaneously:

        r_eff · (1 − cos w_eff) = 16.2 mm   (measured lateral offset)
        r_eff · sin  w_eff      ≈ r_nom · sin w_nom   (preserve X length)

    Solving: w_eff ≈ 23.2° and r_eff ≈ 200 mm.

    These corrected values are applied silently inside this file via the two
    functions below.  All user-facing parameters (branch_angle, radius, …) and
    all entries in Roco_Kato_Adapter.json continue to use the official nominal
    values; the translation to physical reality is entirely internal.

    If you have accurate measurements of other Roco curve radii (R2–R6) or of
    other manufacturers' track, the author would be very grateful if you shared
    them (e.g. via a pull request or an issue on the project repository) so that
    additional correction entries can be added here.
*/
function _eff_w(w, r) = (abs(w - 24) < 0.01 && abs(r - 194.6) < 0.1) ? 23.2 : w;
function _eff_r(w, r) = (abs(w - 24) < 0.01 && abs(r - 194.6) < 0.1) ? 200 : r;

module roco_adapter(
    straight_length = straight_length,
    branch_angle = branch_angle,
    radius = radius,
    connecting_straight_length = connecting_straight_length,
    connected_curve_angle = connected_curve_angle,
    connected_curve_radius = connected_curve_radius,
    drive_length = drive_length,
    drive_width = drive_width,
    drive_offset = drive_offset,
    drive_inset = drive_inset,
    drive_cableslot_diameter = drive_cableslot_diameter,
    drive_cableslot_offset = drive_cableslot_offset,
    enable_entrance_unijoiner = enable_entrance_unijoiner,
    enable_exit_unijoiner_straight = enable_exit_unijoiner_straight,
    enable_exit_unijoiner_curved = enable_exit_unijoiner_curved,
    mirrored = mirrored,
    enable_rims = enable_rims) {
    _w = _eff_w(branch_angle, radius);
    _r = _eff_r(branch_angle, radius);
    _ccw = _eff_w(connected_curve_angle, connected_curve_radius);
    _ccrad = _eff_r(connected_curve_angle, connected_curve_radius);
    difference() {
        union() {
            
            // Entry
            if (enable_entrance_unijoiner) {
                translate([0.001,0,0]) // Epsilon
                rotate([0,0,180])
                        unijoiner_plug();
            }

            // 1. Straight piece
            if (straight_length > 0) {
                straight_section(straight_length);
                if (enable_exit_unijoiner_straight) {
                    translate([-0.001,0,0]);
                    translate([straight_length, 0, 0]) 
                        unijoiner_plug();
                }
            }
            
            // 2. Turnout branch curve
            
            if (branch_angle != 0) {
                
                if (mirrored) {
                    translate([0.001,0,0]) // Epsilon
                    translate([0, -_r, 0])
                         rotate([0, 0, -90])
                            mirror([1,0,0])
                                curved_bed(_r, _w);

                     // Optional straight piece at the end of the turnout curve
                     if (connecting_straight_length > 0) {  
                        translate([-0.001,0,0]) // Epsilon
                        mirror([0,1,0])
                          translate([sin(_w)*_r, _r - cos(_w)*_r, 0])
                            rotate([0, 0, _w])                         
                                    straight_section(connecting_straight_length);
                     }
     

                } else {
                    translate([0.001,0,0]) // Epsilon
                    translate([0, _r, 0])
                         rotate([0, 0, -90])
                            curved_bed(_r, _w);
                    
                     // Optional straight piece at the end of the turnout curve
                     if (connecting_straight_length > 0) {  
                        translate([-0.001,0,0]) // Epsilon
                        translate([sin(_w)*_r, _r - cos(_w)*_r, 0])
                            rotate([0, 0, _w])
                                    straight_section(connecting_straight_length);
                     }
     
 
                 }

                

                
                 // Optional S-curve at the end of the turnout curve (makes exits parallel)
                 if (connected_curve_angle != 0) {  
                   translate([-0.001,0,0]) // Epsilon
                   if (mirrored) {
                       translate([sin(_w)*_r, -(_r - cos(_w)*_r), 0])
                           rotate([0, 0, -_w])
                               translate([0, _ccrad, 0])
                                   rotate([0, 0, -90])
                                       curved_section(_ccrad, _ccw);
                   } else {
                       translate([sin(_w)*_r, _r - cos(_w)*_r, 0])
                           rotate([0, 0, _w])
                               translate([0, -_ccrad, 0])
                                   rotate([0, 0, 90])
                                       curved_section(_ccrad, -_ccw);
                   }
                 }
                 
                
                 if (enable_exit_unijoiner_curved) {
                     
                     if (connected_curve_angle != 0) {
                      translate([-0.001,0,0]) // Epsilon
                      if (mirrored) {
                          translate([sin(_w)*_r, -(_r - cos(_w)*_r), 0])
                              rotate([0, 0, -_w])
                                  translate([_ccrad*sin(_ccw), _ccrad*(1 - cos(_ccw)), 0])
                                      rotate([0, 0, _ccw])
                                          unijoiner_plug();
                      } else {
                          translate([sin(_w)*_r, _r - cos(_w)*_r, 0])
                              rotate([0, 0, _w])
                                  translate([_ccrad*sin(_ccw), -_ccrad*(1 - cos(_ccw)), 0])
                                      rotate([0, 0, -_ccw])
                                          unijoiner_plug();
                      }

                     } else {
                         
                         if (mirrored) {
                        translate([-0.001,0,0]) // Epsilon
                        translate([cos(_w)*connecting_straight_length, -sin(_w)*connecting_straight_length, 0])
                            translate([sin(_w)*_r, -(_r - cos(_w)*_r), 0])
                                rotate([0, 0, -_w])
                                    unijoiner_plug();
                             
                         } else {
                             
                        translate([-0.001,0,0]) // Epsilon
                        translate([cos(_w)*connecting_straight_length, sin(_w)*connecting_straight_length, 0])
                            translate([sin(_w)*_r, _r - cos(_w)*_r, 0])
                                rotate([0, 0, _w])
                                    unijoiner_plug();
                             
                         }
                     }
                }
                
            }
  
            // 3. Drive platform (point motor mount)
            if (drive_length > 0) {
                if (mirrored) {
                translate([drive_offset, bed_width_top / 2, 0]) 
                    drive_box(true, drive_length, drive_width, drive_inset, drive_cableslot_diameter, drive_cableslot_offset);
                } else {
                translate([drive_offset, - bed_width_top / 2 - drive_width, 0]) 
                    drive_box(false, drive_length, drive_width, drive_inset, drive_cableslot_diameter, drive_cableslot_offset);
                }
            }
            
        }

        // --- CUTS ---

        if (enable_entrance_unijoiner) {
                rotate([0,0,180])
            translate([-unijoiner_depth-1,0,0])
                unijoiner_receptable(); // Entry
        }
            
        // Sleeper bed straight, cutout
        if (straight_length > 0) {
            straight_recess(straight_length);
            
            // Unijoiner slot at the end
            if (enable_exit_unijoiner_straight) {
                translate([straight_length -unijoiner_depth-0.9, 0, 0]) // Move back for exits
                        unijoiner_receptable(); 
            }
        }

        // Sleeper bed curved, cutout
        if (branch_angle != 0) {
            
            if (mirrored) {
                translate([0, -_r, 0])
                    rotate([0, 0, -90])
                mirror([1,0,0])
                        curved_recess(_r, _w);
            } else {
                translate([0, _r, 0])
                    rotate([0, 0, -90])
                        curved_recess(_r, _w);
            }
        }

        // Drive platform, cutout
        if (drive_length > 0) {
            if (mirrored) {
            translate([drive_offset, bed_width_top / 2 - 1 , bed_height - recess_depth]) 
                    drive_cut(drive_length, drive_width);
            } else {
            translate([drive_offset, - bed_width_top / 2 - drive_width - 0.2, bed_height - recess_depth]) 
                    drive_cut(drive_length, drive_width);
            }
        }
                
        
        
        if (branch_angle != 0) {
            if (enable_exit_unijoiner_curved) {
                if (connecting_straight_length == 0) {
                    
                    if (connected_curve_angle == 0) {
                    
                        if (mirrored) {
                            // At end of turnout curve
                            translate([sin(_w)*_r, -(_r - cos(_w)*_r), 0])
                                rotate([0, 0, -_w])
                                    translate([-unijoiner_depth-0.9,0,0]) // Move back for exits
                                            unijoiner_receptable();
                        } else {
                            // At end of turnout curve
                            translate([sin(_w)*_r, _r - cos(_w)*_r, 0])
                                rotate([0, 0, _w])
                                    translate([-unijoiner_depth-0.9,0,0]) // Move back for exits

                                            unijoiner_receptable();
                        }
                        
                        } else {

                            if (mirrored) {
                                translate([sin(_w)*_r, -(_r - cos(_w)*_r), 0])
                                    rotate([0, 0, -_w])
                                        translate([_ccrad*sin(_ccw), _ccrad*(1 - cos(_ccw)), 0])
                                            rotate([0, 0, _ccw])
                                                translate([-unijoiner_depth-0.9,0,0]) // Move back for exits
                                                    unijoiner_receptable();
                                
                            } else {
                                // At end of S-curve after turnout curve
                                translate([sin(_w)*_r, _r - cos(_w)*_r, 0])
                                    rotate([0, 0, _w])
                                        translate([_ccrad*sin(_ccw), -_ccrad*(1 - cos(_ccw)), 0])
                                            rotate([0, 0, -_ccw])
                                                translate([-unijoiner_depth-0.9,0,0]) // Move back for exits
                                                    unijoiner_receptable();
                            }
                    }
                   
                } else {
                    
                    if (mirrored) {
                    translate([cos(_w)*connecting_straight_length, -sin(_w)*connecting_straight_length, 0])
                        translate([sin(_w)*_r, -(_r - cos(_w)*_r), 0])
                            rotate([0, 0, -_w])
                                translate([-unijoiner_depth-0.9,0,0]) // Move back for exits
                                        unijoiner_receptable();
                    } else {
                    // At end of straight after curve
                    translate([cos(_w)*connecting_straight_length, sin(_w)*connecting_straight_length, 0])
                        translate([sin(_w)*_r, _r - cos(_w)*_r, 0])
                            rotate([0, 0, _w])
                                translate([-unijoiner_depth-0.9,0,0]) // Move back for exits
                                        unijoiner_receptable();
                    }
                }
            }
        }
        
    }
    
}
/*
    Positioning helpers for layout files.

    after_straight_exit: transforms children to the straight exit of a piece.
    after_curved_exit:   transforms children to the curved exit of a piece,
                         accounting for the curve, optional connecting straight,
                         and optional S-curve using the same formulae as the
                         Remarks block above.
*/
module after_straight_exit(sl = straight_length) {
    translate([sl, 0, 0]) children();
}

module after_curved_exit(
    r   = radius,
    w   = branch_angle,
    csl = connecting_straight_length,
    cca = connected_curve_angle,
    ccr = connected_curve_radius,
    m   = mirrored
) {
    _w = _eff_w(w, r);
    _r = _eff_r(w, r);
    _cca = _eff_w(cca, ccr);
    _ccrad = _eff_r(cca, ccr);
    s = m ? -1 : 1;        // sign: +1 non-mirrored, -1 mirrored
    // Global position at the end of the turnout curve
    cx = _r * sin(_w);
    cy = s * _r * (1 - cos(_w));
    if (cca != 0) {
        // Continued by S-curve: apply curve delta in local frame
        translate([cx, cy, 0])
            rotate([0, 0, s * _w])
                translate([_ccrad * sin(_cca), -s * _ccrad * (1 - cos(_cca)), 0])
                    rotate([0, 0, -s * _cca])
                        children();
    } else {
        // Connecting straight (or nothing if csl == 0) in local frame after curve
        translate([cx, cy, 0])
            rotate([0, 0, s * _w])
                translate([csl, 0, 0])
                    children();
    }
}

     if (is_undef(layout_mode)) roco_adapter();
