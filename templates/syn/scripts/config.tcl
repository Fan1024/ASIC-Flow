# ============================================================
# Design synthesis configuration
# Copy this template and modify for each design.
# ============================================================

set DESIGN_NAME "CHANGE_ME"
set TOP_MODULE  "CHANGE_ME"

if {![info exists SCRIPTS_DIR]} {
    set SCRIPTS_DIR [file normalize [file dirname [info script]]]
}

if {![info exists SYN_DIR]} {
    set SYN_DIR [file normalize "$SCRIPTS_DIR/.."]
}

# Assume syn/ is directly under the RTL project root.
set RTL_ROOT [file normalize "$SYN_DIR/.."]

set FILELIST "$SCRIPTS_DIR/filelist.f"
set SDC_FILE "$SCRIPTS_DIR/constraints.sdc"

set CLOCK_PORT "clk"
set CLOCK_PERIOD 10.0

set GEN_EFF medium
set MAP_OPT_EFF high
set NUM_CPUS 8

set USE_PHYSICAL false
set INSERT_CLOCK_GATING false
