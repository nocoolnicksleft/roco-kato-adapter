
bed_width_top = 18.0;
bed_width_bottom = 25.0;
bed_height = 5.0;

recess_depth = 1.5;
recess_width = bed_width_top - 1.8;
unijoiner_depth = 6;
unijoiner_width = 7;

module bed_profile() {
    polygon(points=[
        [-bed_width_bottom/2, 0],     // bottom left
        [bed_width_bottom/2, 0],      // bottom right
        [bed_width_top/2, bed_height],   // top right
        [-bed_width_top/2, bed_height]   // top left
    ]);
}

module recess_profile() {
    polygon(points=[
        [-recess_width / 2, bed_height - recess_depth],     // bottom left
        [recess_width / 2, bed_height - recess_depth],      // bottom right
        [recess_width / 2, bed_height + 1],   // top right
        [-recess_width / 2, bed_height + 1]   // top left
    ]);
}

module full_profile() {
    difference() {
        bed_profile();
        recess_profile();
    } 
}

module curved_section(r, w) {
    // Curved sleeper bed via rotational extrusion
  rotate_extrude(angle = w, $fn = 360) 
    translate([r,0, 0]) 
        full_profile();
}

module curved_bed(r, w) {
    // Curved sleeper bed via rotational extrusion
  rotate_extrude(angle = w, $fn = 360) 
    translate([r,0, 0]) 
        bed_profile();
}

module curved_recess(r, w) {
  // Curved recess via rotational extrusion
  rotate_extrude(angle = w+0.01, $fn = 360) 
    translate([r,0, 0]) 
        recess_profile();
}

module straight_section(l) {
   rotate(a=[90,0,90])
    linear_extrude(height= l)
        full_profile();
}

module straight_bed(l) {
   rotate(a=[90,0,90])
    linear_extrude(height= l)
        bed_profile();
}

module straight_recess(l) {
   rotate(a=[90,0,90])
    linear_extrude(height= l)
        recess_profile();
}


module unijoiner_receptable(reverse=false,rims=true) {
    slotwidth = 3;
    width_bottom = unijoiner_width;
    height_bottom = 2.8;
    translate([0, reverse ? bed_width_top/4 - unijoiner_width/2 - 1.6 : -bed_width_top/4 - unijoiner_width/2 - 0.4, 0])    
    difference() {
        union() {
            cube([unijoiner_depth + 1, unijoiner_width + 0.8, height_bottom]);
            translate([0,(unijoiner_width + 0.8)/ 2 - slotwidth / 2 ,0]) 
                cube([unijoiner_depth + 1, slotwidth, bed_height - recess_depth]); 
            $fn=360;
            
        }
        if (rims) {
            translate([unijoiner_depth + 0.8 , 0, 0])
                cylinder(h=height_bottom, r=0.5, $fn=360);
            translate([unijoiner_depth + 0.8, width_bottom + 0.8, 0])
                cylinder(h=height_bottom, r=0.5, $fn=360);
        }
    }
}

module unijoiner_plug() {
    width_bottom = unijoiner_width;
    width_middle = 2.8;
    height_bottom = 2.6;
    height_middle = 4.6;

    width_top= width_middle + 0.6;
    height_top = 0.6;
    
    translate([0, bed_width_top/4 - unijoiner_width/2 + 0.2, 0])   
    difference() {
        union() {
            cube([unijoiner_depth, width_bottom, height_bottom]); 
            
            translate([0 + 0.001, width_bottom / 2 - width_middle / 2 + 0.001, 0])
                cube([unijoiner_depth, width_middle, height_middle]); 
  
            translate([0 + 0.002, width_bottom / 2 - width_top / 2 + 0.002, height_middle])
                cube([unijoiner_depth, width_top, height_top]); 

            translate([unijoiner_depth / 3 -0.4, 0, 0])
                cylinder(h=height_bottom, r=0.7, $fn=360);
            translate([unijoiner_depth / 3 -0.4, width_bottom, 0])
                cylinder(h=height_bottom, r=0.7, $fn=360);
        }
    }
}

