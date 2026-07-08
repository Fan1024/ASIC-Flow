# ============================================================
# Nangate45 PDK / standard-cell setup
# Compatible with the array style used in previous JHU Genus scripts.
# ============================================================

puts "Started sourcing [info script]"

# ------------------------------------------------------------
# Root paths
# ------------------------------------------------------------
set PDK(path) "/raid/spring2026/fwu44/pdks/NanGate_45nm/pdk_v1.3_v2010_12/NangateOpenCellLibrary_PDKv1_3_v2010_12"
set PDK(captable_path) "/raid/spring2026/fwu44/pdks/NanGate_45nm/pdk_v1.3_v2010_12/captables"

# ------------------------------------------------------------
# Liberty setup
# ------------------------------------------------------------
if {[array exists STD]} {
    array unset STD
}

set STD(path) "$PDK(path)"
set STD(lib_dir) "$STD(path)/Front_End/Liberty/NLDM"

set STD(typical) "$STD(lib_dir)/NangateOpenCellLibrary_typical.lib"
set STD(fast)    "$STD(lib_dir)/NangateOpenCellLibrary_fast.lib"
set STD(slow)    "$STD(lib_dir)/NangateOpenCellLibrary_slow.lib"

# Default synthesis library.
# For first synthesis pass, typical is easier. Later we can switch to slow.
set SYN_CORNER "typical"
set SYN_LIBS   $STD($SYN_CORNER)

# ------------------------------------------------------------
# Physical files for later physical-aware synthesis / PnR
# ------------------------------------------------------------
set PDK(lef_dir) "$PDK(path)/Back_End/lef"
set PDK(gds_dir) "$PDK(path)/Back_End/gds"
set PDK(verilog_dir) "$PDK(path)/Back_End/verilog"

# Collect LEF files if present.
# Nangate distributions vary slightly, so use broad search.
set PDK(lef) ""
foreach lef_file [glob -nocomplain $PDK(lef_dir)/*.lef $PDK(lef_dir)/*/*.lef] {
    lappend PDK(lef) $lef_file
}
set PDK(lef) [join $PDK(lef)]

# Collect GDS files if present.
set STD(gds) ""
foreach gds_file [glob -nocomplain $PDK(gds_dir)/*.gds $PDK(gds_dir)/*.gds2 $PDK(gds_dir)/*/*.gds $PDK(gds_dir)/*/*.gds2] {
    lappend STD(gds) $gds_file
}
set STD(gds) [join $STD(gds)]

# Captable files for later use; not used by default in first synthesis.
set PDK(captables) ""
foreach cap_file [glob -nocomplain $PDK(captable_path)/*] {
    lappend PDK(captables) $cap_file
}
set PDK(captables) [join $PDK(captables)]

# ------------------------------------------------------------
# Sanity checks
# ------------------------------------------------------------
if {![file exists $PDK(path)]} {
    puts "ERROR: PDK(path) does not exist: $PDK(path)"
    exit 1
}

foreach lib_name {typical fast slow} {
    if {![file exists $STD($lib_name)]} {
        puts "ERROR: Missing Liberty file STD($lib_name): $STD($lib_name)"
        exit 1
    }
}

puts "INFO: Loaded Nangate45 setup"
puts "INFO: PDK(path)   = $PDK(path)"
puts "INFO: SYN_CORNER  = $SYN_CORNER"
puts "INFO: SYN_LIBS    = $SYN_LIBS"
puts "INFO: PDK(lef)    = $PDK(lef)"
puts "INFO: captables   = $PDK(captables)"

parray PDK
parray STD
