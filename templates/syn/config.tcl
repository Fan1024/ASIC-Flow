# ============================================================
# Design-local synthesis configuration
# Copy this file into each repo/syn and modify it.
# ============================================================

set DESIGN_NAME "CHANGE_ME"
set TOP_MODULE  "CHANGE_ME"

# Assumption: this syn/ directory is directly under the RTL repo root.
set RTL_ROOT [file normalize ".."]

set FILELIST "./filelist.f"

set CLOCK_PORT   "clk"
set CLOCK_PERIOD 10.0

# Genus synthesis options
set GEN_EFF      medium
set MAP_OPT_EFF  high
set NUM_CPUS     8

# First pass should be logic synthesis only.
# Turn this on later if Nangate LEF/captable integration is verified.
set USE_PHYSICAL false

# Keep false for first clean baseline.
# Later we can compare clock-gated vs non-clock-gated synthesis.
set INSERT_CLOCK_GATING false
