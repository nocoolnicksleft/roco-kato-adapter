
breite_oben = 18.0;  
breite_unten = 25.0;
hoehe_basis = 5.0;   

ausschnitt_tiefe = 1.5;
unijoiner_tiefe = 6;
unijoiner_breite = 7;

module bett_profil() {
    polygon(points=[
        [-breite_unten/2, 0],     // unten links
        [breite_unten/2, 0],      // unten rechts
        [breite_oben/2, hoehe_basis],   // oben rechts
        [-breite_oben/2, hoehe_basis]   // oben links
    ]);
}

module ausschnitt_profil() {
  breite = breite_oben - 2;
    polygon(points=[
        [-breite / 2, hoehe_basis - ausschnitt_tiefe],     // unten links
        [breite / 2, hoehe_basis - ausschnitt_tiefe],      // unten rechts
        [breite / 2, hoehe_basis + 1],   // oben rechts
        [-breite / 2, hoehe_basis + 1]   // oben links
    ]);
}

module gesamt_profil() {
    difference() {
        bett_profil();
        ausschnitt_profil();
    } 
        
}

module bogen_bett(r, w) {
    // Erzeugt das gebogene Bett durch Extrusion entlang eines Pfades   
  rotate_extrude(angle = w, $fn = 360) 
    translate([r,0, 0]) 
        bett_profil();
}

module bogen_ausschnitt(r, w) {
  // Erzeugt das gebogene Bett durch Extrusion entlang eines Pfades
  rotate_extrude(angle = w+0.01, $fn = 360) 
    translate([r,0, 0]) 
        ausschnitt_profil();
}

module strecke(l) {
   rotate(a=[90,0,90])
    linear_extrude(height= l)
        gesamt_profil();
}

module strecke_bett(l) {
   rotate(a=[90,0,90])
    linear_extrude(height= l)
        bett_profil();
}

module strecke_ausschnitt(l) {
   rotate(a=[90,0,90])
    linear_extrude(height= l)
        ausschnitt_profil();
}


module unijoiner_receptable() {
    slotwidth = 3;
    translate([0, -breite_oben/4 - unijoiner_breite/2 - 0.4, 0])    
    hull() {
        cube([unijoiner_tiefe + 1, unijoiner_breite + 0.2, 2.5]);
        translate([0,unijoiner_breite / 2 - slotwidth / 2 ,0]) 
            cube([unijoiner_tiefe + 1, slotwidth, hoehe_basis - ausschnitt_tiefe]); 
    }
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

