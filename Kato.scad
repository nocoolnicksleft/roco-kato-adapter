
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
       gesamt_profil();
            ausschnitt_profil();
}
