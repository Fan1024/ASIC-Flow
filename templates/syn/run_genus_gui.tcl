# ============================================================
# Genus GUI load entry script
#
# Usage:
#   genus -gui -f ../../run_genus_gui.tcl
#
# This loads:
#   config
#   Nangate PDK
#   timing library
#   RTL
#   elaborated design
#   constraints
#
# It stops before syn_generic / syn_map / syn_opt
# and does not exit Genus.
# ============================================================

set RUN_SYNTH false
set EXIT_AFTER_RUN false
set GUI_MODE true

# Directory containing this script, i.e., repo/syn
set SYN_DIR [file normalize [file dirname [info script]]]

source $SYN_DIR/config.tcl
source $::env(ASIC_FLOW_HOME)/common/pdk/nangate45.tcl
source $::env(ASIC_FLOW_HOME)/common/syn/genus_synth_common.tcl