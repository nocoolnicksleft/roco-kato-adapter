// Varianten
// Nur Weiche Roco 2417
// Mit Roco 2419 R1 Ausgleichsstück 6° 
// Mit Roco 2413 Ausgleichsstück 33.6 mm


// Length of turnout (straight part, 104.2mm on Roco 2417)
laenge = 104.2;      

// Endwinkel des Abzweigs (mit 2419 R1 Ausgleichsstück 6° =30, sonst =24 bei Roco 2417)
winkel = 30;         // 

// Radius des Abzweigs
radius = 194.6;   // [194.6, 228.2, 261.8, 295.4, 329.0, 362.6, 480]

// Länge des am Abzweig befindlichen geraden Stücks (33.6 für Roco 2413)
anschluss_gerade_laenge = 33.6;

// Length of drive platform
drive_length = 88; // 88 Für Weichenantrieb bei Roco 2417

// Width of drive platform
drive_width = 10.0;

// Offset of drive platform from entry
drive_offset = 6;

drive_inset = 4;

enable_entrance_unijoiner = true;

enable_exit_unijoiner = true;

module endofparms() {
    
}

include <Kato.scad>;




module drive_box() {
        inset_height = 1;
        difference() {
            cube([drive_length, drive_width, hoehe_basis]);
            if (drive_inset > 0) {
                translate([0,0,hoehe_basis-ausschnitt_tiefe-inset_height])
                    cube([drive_length, drive_inset, inset_height]);
            }
        }
}

module drive_cut() {
    // Width plus one to eliminate the rim of the bed
    cube([drive_length, drive_width + 1, hoehe_basis]);
}

module unijoiner_receptable() {

    translate([0.0, 1.4, 0.0]) 
        cube([unijoiner_tiefe + 1, unijoiner_breite + 0.2, hoehe_basis-1]); 
}

module unijoiner_plug() {
    width_bottom = unijoiner_breite;
    width_middle = 2.8;
    height_bottom = 2.6;
    height_middle = 4.6;

    width_top= width_middle + 0.6;
    height_top = 0.6;
    
    //width_groove = 1.2;
    //height_groove = 0.8;
    
    translate([0, breite_oben/4 - unijoiner_breite/2, 0])   
    difference() {
        union() {
            cube([unijoiner_tiefe, width_bottom, height_bottom]); 
            
            translate([0, width_bottom / 2 - width_middle / 2, 0])
                cube([unijoiner_tiefe, width_middle, height_middle]); 
  
            translate([0, width_bottom / 2 - width_top / 2, height_middle])
                cube([unijoiner_tiefe, width_top, height_top]); 
        }
 //       translate([0, width_bottom / 2 - width_groove / 2 , 4.0])
 //           cube([unijoiner_tiefe, width_groove, height_groove]); 
    }
}

module roco_2417_curved() {
    difference() {
        union() {

            // Einfahrt
            if (enable_entrance_unijoiner) {
                translate([-unijoiner_tiefe, -10, 0])
                    unijoiner_plug();
            }

            // 1. Gerader Strang            
            if (laenge > 0) {
                strecke(laenge);
                if (enable_exit_unijoiner) {
                    translate([laenge, 0, 0]) 
                        unijoiner_plug();
                }
            }
            
            // 2. Gebogener Abzweig
            
            if (winkel > 0) {
                // Versatz berechnen, damit der Bogen tangential am Nullpunkt startet
                translate([0, radius, 0])
                     rotate([0, 0, -90])
                        bogen_bett(radius, winkel);

                if (enable_exit_unijoiner) {
                    translate([cos(winkel)*anschluss_gerade_laenge, sin(winkel)*anschluss_gerade_laenge, 0])
                        translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                            rotate([0, 0, winkel])
                                unijoiner_plug();
                }
                
                 // Optionales gerades Stück am Ende des Bogens
                 if (anschluss_gerade_laenge > 0) {  
                    // 4. Anschlussgleis gerade 33,6mm (Roco 2413) 
                    translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                        rotate([0, 0, winkel])
                                strecke(anschluss_gerade_laenge);
                 }
                
            }
  
            // 3. Antriebsplattform
            if (drive_length > 0) {
                translate([drive_offset, - breite_oben / 2 - drive_width, 0]) 
                    drive_box();
            }
            
        }

        // --- SCHNITTE ---

        // Unijoiner Taschen
        if (enable_entrance_unijoiner) {
            unijoiner_receptable(); // Einfahrt
        }
            
        // Schwellenbett gerade (Aussparung)
        if (laenge > 0) {
            translate([0, -8.25, hoehe_basis - ausschnitt_tiefe])
                cube([laenge + 0.1, 16.5, ausschnitt_tiefe]);
            
            if (enable_exit_unijoiner) {
                translate([laenge - 6.9, -10, 0]) 
                    unijoiner_receptable(); // Ausgang Gerade
            }
        }

        // Schwellenbett gebogen (Aussparung)
        if (winkel > 0) {
            translate([0, radius, 0])
                rotate([0, 0, -90])
                    bogen_ausschnitt(radius, winkel);
        }

        // Antrieb (Aussparung)
        if (drive_length > 0) {
            translate([drive_offset, - breite_oben / 2 - drive_width - 0.2, hoehe_basis - ausschnitt_tiefe]) 
                    drive_cut();
        }
                
        
        if (winkel > 0) {
            if (enable_exit_unijoiner) {
                if (anschluss_gerade_laenge == 0) {
                    
                    // Ausgang Abzweig (Position am Ende des Bogens)
                    translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                        rotate([0, 0, winkel])
                            translate([-unijoiner_tiefe, -breite_oben/4 - unijoiner_breite/2, 0])
                                cube([7, unijoiner_breite + 0.2, 4.8]); 
                   
                } else {
                    translate([cos(winkel)*anschluss_gerade_laenge, sin(winkel)*anschluss_gerade_laenge, 0])
                        translate([sin(winkel)*radius, radius - cos(winkel)*radius, 0])
                            rotate([0, 0, winkel])
                                translate([-unijoiner_tiefe, -breite_oben/4 - unijoiner_breite/2, 0])
                                    cube([7, unijoiner_breite + 0.2, 4.8]); 
                    
                }
            }
        }
        
        
    }
}

roco_2417_curved();
