

// Length of straight part, 0 to omit
laenge = 104.2;      

// Final angle of curved part, 0 to omit
winkel = 24;         // [0, 6, 15, 24, 30]

// Radius of the curve
radius = 194.6;   // [194.6, 228.2, 261.8, 295.4, 329.0, 362.6, 480]

// Additional straight length at end of the curve, 0 to omit
anschluss_gerade_laenge = 33.6;

// Additional curve at the end of the turnout curve, 0 to omit
connected_curve_angle = 24; // [0, 6, 15, 24, 30]

// Additional curve radius
connected_curve_radius = 194.6; // [194.6, 228.2, 261.8, 295.4, 329.0, 362.6, 480]

/* [Drive Platform] */
// Length of drive platform, 0 to omit
drive_length = 89; // 89 for turnout drive in Roco 2417

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

// Generater Unijoiner at exit end(s)
enable_exit_unijoiner = true;

// Render mirrored over Y axis
mirrored = false;

module endofparms() {
    
}

include <Kato.scad>;



module drive_box() {
        inset_height = 1;
        cable_hole_d = 4;
        $fn=360;
        difference() {
            cube([drive_length, drive_width, hoehe_basis]);
            if (drive_inset > 0) {
                translate([0,0,hoehe_basis-ausschnitt_tiefe-inset_height])
                    cube([drive_length, drive_inset, inset_height]);
            }
            translate([drive_cableslot_offset,3,0])
                cylinder(d = drive_cableslot_diameter, h = hoehe_basis);
        }
        
}

module drive_cut() {
    // Width plus two to eliminate the rim of the bed
    cube([drive_length, drive_width + 2, hoehe_basis]);
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
            if (laenge > 0) {
                strecke(laenge);
                if (enable_exit_unijoiner) {
              translate([-0.001,0,0]);
                    translate([laenge, 0, 0]) 
                        unijoiner_plug();
                }
            }
            
            // 2. Curved piece
            
            if (winkel > 0) {
              translate([0.001,0,0]) // Epsilon
                translate([0, radius, 0])
                     rotate([0, 0, -90])
                        bogen_bett(radius, winkel);


                
                 // Optional straight piece at the end of the turnout curve
                 if (anschluss_gerade_laenge > 0) {  
                    translate([-0.001,0,0]) // Epsilon
                    translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                        rotate([0, 0, winkel])
                                strecke(anschluss_gerade_laenge);
                 }
                
                 // Optional curve piece at the end of the turnout curve
                 if (connected_curve_angle != 0) {  
                   translate([-0.001,0,0]) // Epsilon
                   translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                        rotate([0, 0, winkel])
                            translate([0, -connected_curve_radius, 0])
                                rotate([0, 0, 90])
                                    bogen(connected_curve_radius, -connected_curve_angle);
                 }
                
                 if (enable_exit_unijoiner) {
                     
                     if (connected_curve_angle != 0) {
                      translate([-0.001,0,0]) // Epsilon
                         
                      translate([sin(connected_curve_angle)*connected_curve_radius, cos(connected_curve_angle)*connected_curve_radius - 127, 0])
                         rotate([0, 0, -connected_curve_angle])

                            translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                                rotate([0, 0, winkel])
                         
                                    unijoiner_plug();

                     } else {
                        translate([-0.001,0,0]) // Epsilon
                        translate([cos(winkel)*anschluss_gerade_laenge, sin(winkel)*anschluss_gerade_laenge, 0])
                            translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                                rotate([0, 0, winkel])
                                    unijoiner_plug();
                     }
                }
                
            }
  
            // 3. Drive platform
            if (drive_length > 0) {
                translate([drive_offset, - breite_oben / 2 - drive_width, 0]) 
                    drive_box();
            }
            
        }

        // --- CUTS ---

        if (enable_entrance_unijoiner) {
                rotate([0,0,180])
            translate([-unijoiner_tiefe-1,0,0])
                unijoiner_receptable(); // Einfahrt
        }
            
        // Sleeper bed straight, cutout
        if (laenge > 0) {
            strecke_ausschnitt(laenge);
            
            // Unijoiner slot at the end
            if (enable_exit_unijoiner) {
                translate([laenge -unijoiner_tiefe-1, 0, 0]) // Move back for exits
                        unijoiner_receptable(); 
            }
        }

        // Sleeper bed curved, cutout
        if (winkel > 0) {
            translate([0, radius, 0])
                rotate([0, 0, -90])
                    bogen_ausschnitt(radius, winkel);
        }

        // Drive platform, cutout
        if (drive_length > 0) {
            translate([drive_offset, - breite_oben / 2 - drive_width - 0.2, hoehe_basis - ausschnitt_tiefe]) 
                    drive_cut();
        }
                
        
        
        if (winkel > 0) {
            if (enable_exit_unijoiner) {
                if (anschluss_gerade_laenge == 0) {
                    
                    if (connected_curve_angle == 0) {
                    
                        // At end of turnout curve
                        translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                            rotate([0, 0, winkel])
                                translate([-unijoiner_tiefe-1,0,0]) // Move back for exits
                                        unijoiner_receptable();
                        } else {

                        // At end of curve after turnout curve
                   //     translate([sin(connected_curve_angle)*connected_curve_radius, connected_curve_radius - cos(connected_curve_angle)*connected_curve_radius, 0])
                            translate([0,-127,0])
                            translate([sin(connected_curve_angle)*connected_curve_radius, cos(connected_curve_angle)*connected_curve_radius, 0])
                            rotate([0,0,-connected_curve_angle])
                            translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                                rotate([0, 0, winkel])
                                    translate([-unijoiner_tiefe-0.9,0,0]) // Move back for exits
                                            unijoiner_receptable();
                            
                    }
                   
                } else {
                    // At end of straight after curve
                    translate([cos(winkel)*anschluss_gerade_laenge, sin(winkel)*anschluss_gerade_laenge, 0])
                        translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                            rotate([0, 0, winkel])
                                translate([-unijoiner_tiefe-1,0,0]) // Move back for exits
                                        unijoiner_receptable();
                    
                }
            }
        }
        
    }
    
}

if (mirrored) {
    mirror([0,1,0])
     roco_adapter();
} else {
     roco_adapter();
}
