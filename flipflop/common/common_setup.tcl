
puts "Started sourcing [info script] \n"
set USER  $env(USER)

#-----------------------------------------------------
# PDK Setup
#-----------------------------------------------------
set PDK(path)           "/cadence/kits/installs/CADENCE/GPDK045"
set PDK(lef)            [glob  $PDK(path)/gsclib045_svt_v4.4/gsclib045/lef/gsclib045_tech.lef]
set PDK(qrc_rcworst)    "$PDK(path)/gpdk045_v_6_0/qrc/rcworst/qrcTechFile"
set PDK(qrc_rcbest)     "$PDK(path)/gpdk045_v_6_0/qrc/rcbest/qrcTechFile"
set PDK(qrc_typical)    "$PDK(path)/gpdk045_v_6_0/qrc/typical/qrcTechFile"

parray PDK

#-----------------------------------------------------
# Standard Cell Setup
#-----------------------------------------------------
if {[array exists STD]} {array unset STD}

set STD(path)  "/cadence/kits/installs/CADENCE/GPDK045/gsclib045_svt_v4.4"
set STD(pvt)   "slow_vdd1v0 \
                fast_vdd1v0 \
                fast_vdd1v2 \
                slow_vdd1v2 " 

foreach pvt $STD(pvt) {
    lappend STD($pvt) [glob $STD(path)/gsclib045/timing/${pvt}_basicCells.lib] 
    set STD($pvt)        [join $STD($pvt)] 
}

set STD(lef) [glob $STD(path)/gsclib045/lef/gsclib045_macro.lef]
set STD(gds) [glob $STD(path)/gsclib045/gds/gsclib045.gds]

# eliminate curly braces;
set STD(lef)  [join $STD(lef) ]
set STD(gds)  [join $STD(gds) ]

parray STD
