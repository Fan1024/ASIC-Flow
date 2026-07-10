# ============================================================
# HDL/elaboration/constraint check entry script
#
# Expected launch directory:
#   syn/runs/run_xxx/
#
# Usage:
#   genus -f ../../scripts/run_genus_check.tcl
#
# This mode reads libraries and HDL, elaborates the top module,
# checks unresolved references/blackboxes, reads constraints,
# writes reports and a manifest, and exits before syn_generic.
# ============================================================

set RUN_SYNTH false
set CHECK_ONLY true
set EXIT_AFTER_RUN true
set GUI_MODE false

set SCRIPTS_DIR [file normalize [file dirname [info script]]]
set SYN_DIR     [file normalize "$SCRIPTS_DIR/.."]
set RUN_DIR     [file normalize [pwd]]

set LOG_DIR    "$RUN_DIR/logs"
set REPORT_DIR "$RUN_DIR/reports"
set RESULT_DIR "$RUN_DIR/results"
set OUTPUT_DIR "$RUN_DIR/outputs"
set DB_DIR     "$RUN_DIR/dbs"
set WORK_DIR   "$RUN_DIR/work"
set FV_DIR     "$RUN_DIR/fv"

foreach directory [list \
    $LOG_DIR \
    $REPORT_DIR \
    $RESULT_DIR \
    $OUTPUT_DIR \
    $DB_DIR \
    $WORK_DIR \
    $FV_DIR \
] {
    file mkdir $directory
}

puts "INFO: SCRIPTS_DIR = $SCRIPTS_DIR"
puts "INFO: SYN_DIR     = $SYN_DIR"
puts "INFO: RUN_DIR     = $RUN_DIR"

if {![info exists ::env(ASIC_FLOW_HOME)] ||
    [string trim $::env(ASIC_FLOW_HOME)] eq ""} {
    puts "ERROR: ASIC_FLOW_HOME is not set"
    exit 1
}

source "$SCRIPTS_DIR/config.tcl"

if {![info exists PDK_NAME] || [string trim $PDK_NAME] eq ""} {
    set PDK_NAME "nangate45"
}

set PDK_SETUP [file normalize \
    "$::env(ASIC_FLOW_HOME)/common/pdk/${PDK_NAME}.tcl"]
set HELPER_SCRIPT [file normalize \
    "$::env(ASIC_FLOW_HOME)/common/syn/genus_helpers.tcl"]
set COMMON_SCRIPT [file normalize \
    "$::env(ASIC_FLOW_HOME)/common/syn/genus_synth_common.tcl"]

foreach required_script [list \
    $PDK_SETUP \
    $HELPER_SCRIPT \
    $COMMON_SCRIPT \
] {
    if {![file isfile $required_script]} {
        puts "ERROR: Required flow script does not exist: $required_script"
        exit 1
    }
}

source $PDK_SETUP
source $HELPER_SCRIPT
source $COMMON_SCRIPT
