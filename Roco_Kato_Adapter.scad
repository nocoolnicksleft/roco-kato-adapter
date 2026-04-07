

// Length of the straight entry section, 0 to omit
straight_length = 104.2;      

// Branch angle of the turnout curve, 0 for straight track only
branch_angle = 24;         // [0, 6, 15, 24, 30]

// Radius of the turnout curve
radius = 194.6;   // [194.6, 228.2, 261.8, 295.4, 329.0, 362.6, 480]

// Straight section appended to end of branch curve, 0 to omit
connecting_straight_length = 33.6;

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



module drive_box(reverse) {
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

module drive_cut() {
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

module unijoiner_plug_rev() {
    width_bottom = unijoiner_width;
    width_middle = 2.8;
    height_bottom = 2.6;
    height_middle = 4.6;

    width_top= width_middle + 0.6;
    height_top = 0.6;
    
    //width_groove = 1.2;
    //height_groove = 0.8;
    
    translate([0, -bed_width_top/4 - unijoiner_width/2, 0])   
    difference() {
        union() {
            cube([unijoiner_depth, width_bottom, height_bottom]); 
            
            translate([0 + 0.001, width_bottom / 2 - width_middle / 2 + 0.001, 0])
                cube([unijoiner_depth, width_middle, height_middle]); 
  
            translate([0 + 0.002, width_bottom / 2 - width_top / 2 + 0.002, height_middle])
                cube([unijoiner_depth, width_top, height_top]); 
        }
 //       translate([0, width_bottom / 2 - width_groove / 2 , 4.0])
 //           cube([unijoiner_depth, width_groove, height_groove]); 
    }
}
module roco_adapter() {
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
                    translate([0, -radius, 0])
                         rotate([0, 0, -90])
                            mirror([1,0,0])
                                curved_bed(radius, branch_angle);

                     // Optional straight piece at the end of the turnout curve
                     if (connecting_straight_length > 0) {  
                        translate([-0.001,0,0]) // Epsilon
                        mirror([0,1,0])
                          translate([sin(branch_angle)*radius, radius - cos(branch_angle)*radius, 0])
                            rotate([0, 0, branch_angle])                         
                                    straight_section(connecting_straight_length);
                     }
     

                } else {
                    translate([0.001,0,0]) // Epsilon
                    translate([0, radius, 0])
                         rotate([0, 0, -90])
                            curved_bed(radius, branch_angle);
                    
                     // Optional straight piece at the end of the turnout curve
                     if (connecting_straight_length > 0) {  
                        translate([-0.001,0,0]) // Epsilon
                        translate([sin(branch_angle)*radius, radius - cos(branch_angle)*radius, 0])
                            rotate([0, 0, branch_angle])
                                    straight_section(connecting_straight_length);
                     }
     
 
                 }

                

                
                 // Optional S-curve at the end of the turnout curve (makes exits parallel)
                 if (connected_curve_angle != 0) {  
                   translate([-0.001,0,0]) // Epsilon
                   if (mirrored) {
                       translate([sin(branch_angle)*radius, -(radius - cos(branch_angle)*radius), 0])
                           rotate([0, 0, -branch_angle])
                               translate([0, connected_curve_radius, 0])
                                   rotate([0, 0, -90])
                                       curved_section(connected_curve_radius, connected_curve_angle);
                   } else {
                       translate([sin(branch_angle)*radius, radius - cos(branch_angle)*radius, 0])
                           rotate([0, 0, branch_angle])
                               translate([0, -connected_curve_radius, 0])
                                   rotate([0, 0, 90])
                                       curved_section(connected_curve_radius, -connected_curve_angle);
                   }
                 }
                 
                
                 if (enable_exit_unijoiner_curved) {
                     
                     if (connected_curve_angle != 0) {
                      translate([-0.001,0,0]) // Epsilon
                      if (mirrored) {
                          translate([sin(branch_angle)*radius, -(radius - cos(branch_angle)*radius), 0])
                              rotate([0, 0, -branch_angle])
                                  translate([connected_curve_radius*sin(connected_curve_angle), connected_curve_radius*(1 - cos(connected_curve_angle)), 0])
                                      rotate([0, 0, connected_curve_angle])
                                          unijoiner_plug();
                      } else {
                          translate([sin(branch_angle)*radius, radius - cos(branch_angle)*radius, 0])
                              rotate([0, 0, branch_angle])
                                  translate([connected_curve_radius*sin(connected_curve_angle), -connected_curve_radius*(1 - cos(connected_curve_angle)), 0])
                                      rotate([0, 0, -connected_curve_angle])
                                          unijoiner_plug();
                      }

                     } else {
                         
                         if (mirrored) {
                        translate([-0.001,0,0]) // Epsilon
                        translate([cos(branch_angle)*connecting_straight_length, -sin(branch_angle)*connecting_straight_length, 0])
                            translate([sin(branch_angle)*radius, -(radius - cos(branch_angle)*radius), 0])
                                rotate([0, 0, -branch_angle])
                                    unijoiner_plug();
                             
                         } else {
                             
                        translate([-0.001,0,0]) // Epsilon
                        translate([cos(branch_angle)*connecting_straight_length, sin(branch_angle)*connecting_straight_length, 0])
                            translate([sin(branch_angle)*radius, radius - cos(branch_angle)*radius, 0])
                                rotate([0, 0, branch_angle])
                                    unijoiner_plug();
                             
                         }
                     }
                }
                
            }
  
            // 3. Drive platform (point motor mount)
            if (drive_length > 0) {
                if (mirrored) {
                translate([drive_offset, bed_width_top / 2, 0]) 
                    drive_box(true);
                } else {
                translate([drive_offset, - bed_width_top / 2 - drive_width, 0]) 
                    drive_box(false);
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
                translate([straight_length -unijoiner_depth-1, 0, 0]) // Move back for exits
                        unijoiner_receptable(); 
            }
        }

        // Sleeper bed curved, cutout
        if (branch_angle != 0) {
            
            if (mirrored) {
                translate([0, -radius, 0])
                    rotate([0, 0, -90])
                mirror([1,0,0])
                        curved_recess(radius, branch_angle);
            } else {
                translate([0, radius, 0])
                    rotate([0, 0, -90])
                        curved_recess(radius, branch_angle);
            }
        }

        // Drive platform, cutout
        if (drive_length > 0) {
            if (mirrored) {
            translate([drive_offset, bed_width_top / 2 - 1 , bed_height - recess_depth]) 
                    drive_cut();
            } else {
            translate([drive_offset, - bed_width_top / 2 - drive_width - 0.2, bed_height - recess_depth]) 
                    drive_cut();
            }
        }
                
        
        
        if (branch_angle != 0) {
            if (enable_exit_unijoiner_curved) {
                if (connecting_straight_length == 0) {
                    
                    if (connected_curve_angle == 0) {
                    
                        if (mirrored) {
                            // At end of turnout curve
                            translate([sin(branch_angle)*radius, -(radius - cos(branch_angle)*radius), 0])
                                rotate([0, 0, -branch_angle])
                                    translate([-unijoiner_depth-0.9,0,0]) // Move back for exits
                                            unijoiner_receptable();
                        } else {
                            // At end of turnout curve
                            translate([sin(branch_angle)*radius, radius - cos(branch_angle)*radius, 0])
                                rotate([0, 0, branch_angle])
                                    translate([-unijoiner_depth-0.9,0,0]) // Move back for exits

                                            unijoiner_receptable();
                        }
                        
                        } else {

                            if (mirrored) {
                                translate([sin(branch_angle)*radius, -(radius - cos(branch_angle)*radius), 0])
                                    rotate([0, 0, -branch_angle])
                                        translate([connected_curve_radius*sin(connected_curve_angle), connected_curve_radius*(1 - cos(connected_curve_angle)), 0])
                                            rotate([0, 0, connected_curve_angle])
                                                translate([-unijoiner_depth-0.9,0,0]) // Move back for exits
                                                    unijoiner_receptable();
                                
                            } else {
                                // At end of S-curve after turnout curve
                                translate([sin(branch_angle)*radius, radius - cos(branch_angle)*radius, 0])
                                    rotate([0, 0, branch_angle])
                                        translate([connected_curve_radius*sin(connected_curve_angle), -connected_curve_radius*(1 - cos(connected_curve_angle)), 0])
                                            rotate([0, 0, -connected_curve_angle])
                                                translate([-unijoiner_depth-0.9,0,0]) // Move back for exits
                                                    unijoiner_receptable();
                            }
                    }
                   
                } else {
                    
                    if (mirrored) {
                    translate([cos(branch_angle)*connecting_straight_length, -sin(branch_angle)*connecting_straight_length, 0])
                        translate([sin(branch_angle)*radius, -(radius - cos(branch_angle)*radius), 0])
                            rotate([0, 0, -branch_angle])
                                translate([-unijoiner_depth-0.9,0,0]) // Move back for exits
                                        unijoiner_receptable();
                    } else {
                    // At end of straight after curve
                    translate([cos(branch_angle)*connecting_straight_length, sin(branch_angle)*connecting_straight_length, 0])
                        translate([sin(branch_angle)*radius, radius - cos(branch_angle)*radius, 0])
                            rotate([0, 0, branch_angle])
                                translate([-unijoiner_depth-0.9,0,0]) // Move back for exits
                                        unijoiner_receptable();
                    }
                }
            }
        }
        
    }
    
}
     roco_adapter();
