# ============================================================
# Genus GUI load entry script
#
# Expected launch directory:
#   syn/runs/run_xxx/
#
# Usage:
#   genus -gui -f ../../scripts/run_genus_gui.tcl
#
# This loads library, RTL, elaboration, and constraints,
# then stops before syn_generic / syn_map / syn_opt.
# ============================================================

set RUN_SYNTH false
set EXIT_AFTER_RUN false
set GUI_MODE true

set SCRIPTS_DIR [file normalize [file dirname [info script]]]
set SYN_DIR     [file normalize "$SCRIPTS_DIR/.."]
set RUN_DIR     [file normalize [pwd]]

set LOG_DIR     "$RUN_DIR/logs"
set REPORT_DIR  "$RUN_DIR/reports"
set RESULT_DIR  "$RUN_DIR/results"
set OUTPUT_DIR  "$RUN_DIR/outputs"
set DB_DIR      "$RUN_DIR/dbs"
set WORK_DIR    "$RUN_DIR/work"
set FV_DIR      "$RUN_DIR/fv"

foreach d [list $LOG_DIR $REPORT_DIR $RESULT_DIR $OUTPUT_DIR $DB_DIR $WORK_DIR $FV_DIR] {
    file mkdir $d
}

puts "INFO: SCRIPTS_DIR = $SCRIPTS_DIR"
puts "INFO: SYN_DIR     = $SYN_DIR"
puts "INFO: RUN_DIR     = $RUN_DIR"

source $SCRIPTS_DIR/config.tcl
source $::env(ASIC_FLOW_HOME)/common/pdk/nangate45.tcl
source $::env(ASIC_FLOW_HOME)/common/syn/genus_synth_common.tcl
