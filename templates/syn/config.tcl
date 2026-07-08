cd /raid/spring2026/fwu44/research/picorv32/syn

cat > config.tcl <<'EOF'
# ============================================================
# PicoRV32 synthesis configuration
# ============================================================

set DESIGN_NAME "CHANGE_ME"
set TOP_MODULE  "CHANGE_ME"

# SYN_DIR is set by run_genus.tcl / run_genus_gui.tcl.
# If this file is sourced manually, fall back to current directory.
if {![info exists SYN_DIR]} {
    set SYN_DIR [file normalize "."]
}

# syn/ is directly under the RTL repo root.
set RTL_ROOT [file normalize "$SYN_DIR/.."]

set FILELIST "$SYN_DIR/filelist.f"
set SDC_FILE "$SYN_DIR/constraints.sdc"

set CLOCK_PORT   "clk"
set CLOCK_PERIOD 10.0

# Genus synthesis options
set GEN_EFF      medium
set MAP_OPT_EFF  high
set NUM_CPUS     8

# First pass: logic synthesis only.
set USE_PHYSICAL false

# First baseline: no clock gating.
set INSERT_CLOCK_GATING false