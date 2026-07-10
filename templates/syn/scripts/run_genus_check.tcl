# ============================================================
# HDL/elaboration/constraint check entry
#
# This mode:
#   1. reads libraries;
#   2. reads RTL and packages;
#   3. elaborates the top;
#   4. reads constraints;
#   5. runs design/timing checks;
#   6. exits before syn_generic.
# ============================================================

set RUN_SYNTH false
set EXIT_AFTER_RUN true
set GUI_MODE false
set CHECK_ONLY true

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