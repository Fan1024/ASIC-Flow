# ============================================================
# Complete synthesis from an already loaded Genus GUI session
#
# The GUI should have been opened with:
#   make syn_gui
#
# Then run in the Genus Tcl console:
#   source <design>/syn/scripts/gui_write.tcl
# ============================================================

if {![info exists DESIGN_NAME] || [string trim $DESIGN_NAME] eq ""} {
    error "DESIGN_NAME is not defined. Load the design with run_genus_gui.tcl first."
}

if {![info exists OUTPUT]} {
    set OUTPUT "./results/${DESIGN_NAME}.SYN"
}
if {![info exists REP_GUI]} {
    set REP_GUI "./reports/gui"
}
if {![info exists GEN_EFF]} {
    set GEN_EFF medium
}
if {![info exists MAP_OPT_EFF]} {
    set MAP_OPT_EFF high
}

file mkdir ./outputs
file mkdir ./dbs
file mkdir $OUTPUT
file mkdir $REP_GUI

safe_set_db / .syn_generic_effort $GEN_EFF
puts "INFO: GUI flow running syn_generic"
syn_generic
write_snapshot -outdir ./dbs/ -tag gui_generic

safe_set_db / .syn_map_effort $MAP_OPT_EFF
puts "INFO: GUI flow running syn_map"
syn_map
write_snapshot -outdir ./dbs/ -tag gui_map

safe_set_db / .remove_assigns true
safe_set_db / .use_tiehilo_for_const none
safe_set_db / .syn_opt_effort $MAP_OPT_EFF
puts "INFO: GUI flow running syn_opt"
syn_opt
write_snapshot -outdir ./dbs/ -tag gui_opt

write_hdl > "$OUTPUT/${DESIGN_NAME}.mapped.v"
write_sdc > "$OUTPUT/${DESIGN_NAME}.mapped.sdc"

file copy -force "$OUTPUT/${DESIGN_NAME}.mapped.v" \
    "./outputs/${DESIGN_NAME}_mapped.v"
file copy -force "$OUTPUT/${DESIGN_NAME}.mapped.sdc" \
    "./outputs/${DESIGN_NAME}.sdc"

report_timing -path_type full -max_path 100 \
    > "$REP_GUI/${DESIGN_NAME}.gui.after_opt_timing.rpt"
report_gates \
    > "$REP_GUI/${DESIGN_NAME}.gui.after_opt_gates.rpt"
report_power \
    > "$REP_GUI/${DESIGN_NAME}.gui.after_opt_power.rpt"
report_messages -all \
    > "$REP_GUI/${DESIGN_NAME}.gui.after_opt_messages.rpt"

if {[llength [info commands flow_write_manifest]] > 0} {
    set gui_manifest "$OUTPUT/${DESIGN_NAME}.gui.manifest.txt"
    flow_write_manifest $gui_manifest "gui_mapped_synthesis"
    file copy -force $gui_manifest \
        "./outputs/${DESIGN_NAME}_gui_manifest.txt"
}

puts "============================================================"
puts "INFO: GUI synthesis completed for $DESIGN_NAME"
puts "INFO: Netlist: $OUTPUT/${DESIGN_NAME}.mapped.v"
puts "INFO: SDC:     $OUTPUT/${DESIGN_NAME}.mapped.sdc"
puts "============================================================"
