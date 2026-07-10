# ============================================================
# GUI synthesis entry script
# ============================================================

set RUN_SYNTH true
set EXIT_AFTER_RUN false
set GUI_MODE true
set CHECK_ONLY false

set SCRIPTS_DIR [file normalize [file dirname [info script]]]
set SYN_DIR     [file normalize "$SCRIPTS_DIR/.."]
set RUN_DIR     [file normalize [pwd]]

foreach directory {
    logs
    reports
    results
    outputs
    dbs
    work
    fv
} {
    file mkdir "$RUN_DIR/$directory"
}

puts "INFO: SCRIPTS_DIR = $SCRIPTS_DIR"
puts "INFO: SYN_DIR     = $SYN_DIR"
puts "INFO: RUN_DIR     = $RUN_DIR"

source "$SCRIPTS_DIR/config.tcl"

if {![info exists PDK_NAME] || [string trim $PDK_NAME] eq ""} {
    set PDK_NAME "nangate45"
}

set PDK_SETUP \
    "$::env(ASIC_FLOW_HOME)/common/pdk/${PDK_NAME}.tcl"

if {![file isfile $PDK_SETUP]} {
    puts "ERROR: PDK setup does not exist: $PDK_SETUP"
    exit 1
}

source $PDK_SETUP
source "$::env(ASIC_FLOW_HOME)/common/syn/genus_helpers.tcl"
source "$::env(ASIC_FLOW_HOME)/common/syn/genus_synth_common.tcl"