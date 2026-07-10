# ============================================================
# Design synthesis configuration
#
# Copy this template into each design's syn/scripts directory.
# Only design-specific values should be changed here.
# ============================================================

set DESIGN_NAME "CHANGE_ME"
set TOP_MODULE  "CHANGE_ME"

if {![info exists SCRIPTS_DIR]} {
    set SCRIPTS_DIR [file normalize [file dirname [info script]]]
}

if {![info exists SYN_DIR]} {
    set SYN_DIR [file normalize "$SCRIPTS_DIR/.."]
}

# Default assumption:
#
#   design/
#   +-- rtl/...
#   +-- syn/
#       +-- scripts/
#
set RTL_ROOT [file normalize "$SYN_DIR/.."]

# ------------------------------------------------------------
# HDL inputs
# ------------------------------------------------------------

# Legacy single-filelist interface.
# Kept for backward compatibility with the current PicoRV32 flow.
set FILELIST "$SCRIPTS_DIR/filelist.f"

# Preferred interfaces for larger SystemVerilog projects.
#
# Filelists are read in the order listed here.
set HDL_FILELISTS {}

# Package files are read before all filelists and RTL files.
set HDL_PACKAGE_FILES {}

# Explicit RTL files are read after package files and filelists.
set HDL_RTL_FILES {}

# Directories used to resolve `include files.
set HDL_INCLUDE_DIRS {}

# Examples:
#   SYNTHESIS
#   RV32
#   MY_FEATURE=1
set HDL_DEFINES [list SYNTHESIS]

# Optional design-specific Tcl hooks.
set PRE_READ_TCL  ""
set POST_READ_TCL ""

# ------------------------------------------------------------
# Timing constraints
# ------------------------------------------------------------
set SDC_FILE "$SCRIPTS_DIR/constraints.sdc"
set CLOCK_PORT "clk"
set CLOCK_PERIOD 10.0

# ------------------------------------------------------------
# Synthesis controls
# ------------------------------------------------------------
set GEN_EFF medium
set MAP_OPT_EFF high
set NUM_CPUS 8

set USE_PHYSICAL false
set INSERT_CLOCK_GATING false

# ------------------------------------------------------------
# PDK configuration
# ------------------------------------------------------------
set PDK_NAME "nangate45"