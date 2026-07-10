# ============================================================
# Design synthesis configuration
#
# Copy this template into each design's syn/scripts directory.
# Only design-specific values should be changed in that copy.
# ============================================================

# ------------------------------------------------------------
# Design identity
# ------------------------------------------------------------
set DESIGN_NAME "CHANGE_ME"
set TOP_MODULE  "CHANGE_ME"

# ------------------------------------------------------------
# Directory discovery
# ------------------------------------------------------------
if {![info exists SCRIPTS_DIR]} {
    set SCRIPTS_DIR [file normalize [file dirname [info script]]]
}

if {![info exists SYN_DIR]} {
    set SYN_DIR [file normalize "$SCRIPTS_DIR/.."]
}

# Default project layout:
#
#   design_root/
#     rtl/...
#     syn/
#       Makefile
#       scripts/
#
# The benchmark-specific config may replace RTL_ROOT when its
# repository uses a different layout.
set RTL_ROOT [file normalize "$SYN_DIR/.."]

# ------------------------------------------------------------
# HDL inputs
# ------------------------------------------------------------

# Legacy single-filelist interface.  This keeps the existing
# PicoRV32-style flow backward compatible.  It is used only if
# HDL_FILELISTS, HDL_PACKAGE_FILES, and HDL_RTL_FILES are all
# empty.
set FILELIST "$SCRIPTS_DIR/filelist.f"

# Preferred interface for larger SystemVerilog projects.
# Filelists are read in the exact order declared here.
# Example:
#   set HDL_FILELISTS [list \
#       "$SCRIPTS_DIR/packages.f" \
#       "$SCRIPTS_DIR/rtl.f" \
#   ]
set HDL_FILELISTS {}

# Explicit package files are read before every filelist and
# before HDL_RTL_FILES.  Preserve package dependency order.
# Example:
#   set HDL_PACKAGE_FILES [list \
#       "$RTL_ROOT/rtl/example_pkg.sv" \
#   ]
set HDL_PACKAGE_FILES {}

# Explicit source files are read after package files and
# ordered filelists.
set HDL_RTL_FILES {}

# Directories used to resolve HDL source/include files.
# Example:
#   set HDL_INCLUDE_DIRS [list \
#       "$RTL_ROOT/rtl" \
#       "$RTL_ROOT/vendor/example/rtl" \
#   ]
set HDL_INCLUDE_DIRS {}

# Global Verilog/SystemVerilog macros supplied to every
# read_hdl invocation.
# Examples:
#   SYNTHESIS
#   RV32
#   FEATURE_ENABLE=1
set HDL_DEFINES [list SYNTHESIS]

# Optional design-specific Tcl hooks.  Keep them empty unless
# a benchmark needs additional setup around read_hdl.
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
# PDK selection
# Corresponding file:
#   $ASIC_FLOW_HOME/common/pdk/${PDK_NAME}.tcl
# ------------------------------------------------------------
set PDK_NAME "nangate45"
