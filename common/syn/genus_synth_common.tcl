# ============================================================
# Common Cadence Genus synthesis flow
#
# This script follows the style of the existing JHU scripts:
#   read_libs
#   syn_generic
#   syn_map
#   syn_opt
#   report_summary
#   write_snapshot
#
# Required from local config.tcl:
#   DESIGN_NAME
#   TOP_MODULE
#   RTL_ROOT
#   FILELIST
#   CLOCK_PORT
#   CLOCK_PERIOD
#
# Required from common/pdk/nangate45.tcl:
#   SYN_LIBS
# ============================================================

alias h history

set hostname [info hostname]
puts "Hostname : $hostname"

# ------------------------------------------------------------
# Defaults that can be overridden in local config.tcl
# ------------------------------------------------------------
if {![info exists GEN_EFF]}      { set GEN_EFF medium }
if {![info exists MAP_OPT_EFF]}  { set MAP_OPT_EFF high }
if {![info exists NUM_CPUS]}     { set NUM_CPUS 8 }
if {![info exists USE_PHYSICAL]} { set USE_PHYSICAL false }
if {![info exists INSERT_CLOCK_GATING]} { set INSERT_CLOCK_GATING false }

# ------------------------------------------------------------
# Directory setup
# ------------------------------------------------------------
set REP_GEN ./reports/generic
set REP_MAP ./reports/map
set REP_OPT ./reports/opt
set REP_INC ./reports/inc
set OUTPUT  ./results/${DESIGN_NAME}.SYN

file mkdir logs
file mkdir reports
file mkdir $REP_GEN
file mkdir $REP_MAP
file mkdir $REP_OPT
file mkdir $REP_INC
file mkdir results
file mkdir $OUTPUT
file mkdir dbs
file mkdir work

puts "============================================================"
puts "INFO: Starting synthesis"
puts "INFO: DESIGN_NAME         = $DESIGN_NAME"
puts "INFO: TOP_MODULE          = $TOP_MODULE"
puts "INFO: RTL_ROOT            = $RTL_ROOT"
puts "INFO: FILELIST            = $FILELIST"
puts "INFO: CLOCK_PORT          = $CLOCK_PORT"
puts "INFO: CLOCK_PERIOD        = $CLOCK_PERIOD"
puts "INFO: SYN_LIBS            = $SYN_LIBS"
puts "INFO: GEN_EFF             = $GEN_EFF"
puts "INFO: MAP_OPT_EFF         = $MAP_OPT_EFF"
puts "INFO: USE_PHYSICAL        = $USE_PHYSICAL"
puts "INFO: INSERT_CLOCK_GATING = $INSERT_CLOCK_GATING"
puts "============================================================"

# ------------------------------------------------------------
# Helper for optional set_db commands
# ------------------------------------------------------------
proc safe_set_db {args} {
    if {[catch {eval set_db $args} msg]} {
        puts "WARNING: set_db $args failed: $msg"
    }
}

# ------------------------------------------------------------
# Run settings
# ------------------------------------------------------------
safe_set_db max_cpus_per_server $NUM_CPUS
safe_set_db information_level 7
safe_set_db lef_stop_on_error true

# Verilog / HDL settings
safe_set_db hdl_preserve_unused_registers false
safe_set_db hdl_preserve_unused_flop false
safe_set_db hdl_unconnected_value 0
safe_set_db hdl_create_label_for_unlabeled_generate false
safe_set_db hdl_array_naming_style %s\[%d\]
safe_set_db hdl_track_filename_row_col true
safe_set_db ungroup_separator /
safe_set_db hdl_vhdl_read_version 2008
safe_set_db write_vlog_unconnected_port_style none
safe_set_db print_ports_nets_preserved_for_cb true

# Mapping settings
safe_set_db use_scan_seqs_for_non_dft false
safe_set_db init_blackbox_for_undefined false
safe_set_db ultra_global_mapping true
safe_set_db / .auto_ungroup none

# Power settings
safe_set_db lp_insert_clock_gating $INSERT_CLOCK_GATING
safe_set_db lp_power_analysis_effort high
safe_set_db lp_power_unit mW
safe_set_db leakage_power_effort medium
safe_set_db design_power_effort low
safe_set_db opt_leakage_to_dynamic_ratio 0.5

# SDC settings
safe_set_db detailed_sdc_messages true

# ------------------------------------------------------------
# Library setup
# ------------------------------------------------------------
if {![file exists $SYN_LIBS]} {
    puts "ERROR: SYN_LIBS does not exist: $SYN_LIBS"
    exit 1
}

puts "INFO: Reading timing libraries using read_libs"
read_libs $SYN_LIBS

# Optional physical-aware synthesis.
# Disabled by default because Nangate may not provide a full qrcTechFile.
if {$USE_PHYSICAL} {
    if {[info exists PDK(lef)] && $PDK(lef) ne ""} {
        puts "INFO: Reading LEF files"
        read_physical -lef $PDK(lef)
    } else {
        puts "WARNING: USE_PHYSICAL is true, but PDK(lef) is empty"
    }

    if {[info exists PDK(qrc_rcworst)] && [file exists $PDK(qrc_rcworst)]} {
        puts "INFO: Reading QRC file: $PDK(qrc_rcworst)"
        read_qrc $PDK(qrc_rcworst)
    } else {
        puts "WARNING: No valid QRC file found for this PDK. Skipping read_qrc."
    }
}

# ------------------------------------------------------------
# Read RTL
# ------------------------------------------------------------
if {![file exists $FILELIST]} {
    puts "ERROR: FILELIST does not exist: $FILELIST"
    exit 1
}

puts "INFO: Reading RTL from filelist: $FILELIST"
read_hdl -sv -f $FILELIST

# ------------------------------------------------------------
# Elaborate
# ------------------------------------------------------------
puts "INFO: Elaborating top module: $TOP_MODULE"
elaborate $TOP_MODULE

# Rename current design to DESIGN_NAME if needed.
# Usually DESIGN_NAME == TOP_MODULE, so this is not necessary.
# rename_object [get_db designs] $DESIGN_NAME

uniquify $TOP_MODULE -verbose

time_info Elaboration

puts "Num FFs after elaboration: [llength [get_db insts -if {.is_flop == true}]]"

check_design -unresolved
check_design -all > $REP_GEN/${DESIGN_NAME}.check_design.rpt

set SYNTH(BlackBox)   [llength [get_db design:$TOP_MODULE .blackboxes]]
set SYNTH(Unresolved) [llength [get_db hinsts -if {.unresolved==true}]]

if {$SYNTH(BlackBox) || $SYNTH(Unresolved)} {
    puts "\nERROR: Unresolved references or blackboxes in design. Exit.\n"
    puts "ERROR: BlackBox count   = $SYNTH(BlackBox)"
    puts "ERROR: Unresolved count = $SYNTH(Unresolved)"
    exit 1
}

# ------------------------------------------------------------
# Constraints
# ------------------------------------------------------------
set_units -time ns
set_units -capacitance fF

if {[file exists "./constraints.sdc"]} {
    puts "INFO: Reading constraints.sdc"
    read_sdc ./constraints.sdc
} else {
    puts "WARNING: constraints.sdc not found. Creating basic clock."
    create_clock -name $CLOCK_PORT -period $CLOCK_PERIOD [get_ports $CLOCK_PORT]
}

if {[info exists ::dc::sdc_failed_commands]} {
    echo $::dc::sdc_failed_commands > reports/sdc_failed_commands.rpt
}

set fp_excep [open "./reports/exceptions.rpt" "w"]
foreach excep [get_db exceptions] {
    set line "[get_db $excep .name] \t [get_db $excep .exception_type] \t [get_db $excep .priority]"
    puts $line
    puts $fp_excep $line
}
close $fp_excep

check_timing_intent -verbose > $REP_GEN/check_timing.rpt

# ------------------------------------------------------------
# Cost groups
# ------------------------------------------------------------
define_cost_group -name I2O -design $TOP_MODULE
define_cost_group -name I2C -design $TOP_MODULE
define_cost_group -name C2O -design $TOP_MODULE
define_cost_group -name C2C -design $TOP_MODULE

path_group -from [all_registers] -to [all_registers] -group C2C -name C2C
path_group -from [all_registers] -to [all_outputs]   -group C2O -name C2O
path_group -from [all_inputs]    -to [all_registers] -group I2C -name I2C
path_group -from [all_inputs]    -to [all_outputs]   -group I2O -name I2O

# ------------------------------------------------------------
# Generic synthesis
# ------------------------------------------------------------
safe_set_db / .syn_generic_effort $GEN_EFF

puts "INFO: Running syn_generic"
syn_generic

time_info GENERIC

report_dp > $REP_GEN/${DESIGN_NAME}.generic.datapath.rpt
write_snapshot -outdir ./dbs/ -tag generic
report_summary -directory $REP_GEN

# ------------------------------------------------------------
# Mapping
# ------------------------------------------------------------
safe_set_db / .syn_map_effort $MAP_OPT_EFF

puts "INFO: Running syn_map"
syn_map

time_info MAPPED

write_snapshot -outdir ./dbs/ -tag map
report_summary -directory $REP_MAP

set num_regs [llength [get_db insts -if {.is_flop == true}]]
set num_nets [get_db designs .num_nets]
echo "Num FFs: $num_regs\nNum Nets: $num_nets" > ${REP_MAP}/stats.map.rpt

foreach cg [get_db designs .cost_groups] {
    set cg_name [get_db $cg .name]
    report_timing -path_type full     -max_path 1000 -cost_group [list $cg] > $REP_MAP/${DESIGN_NAME}.map.${cg_name}_full.rpt.gz
    report_timing -path_type endpoint -max_path 1000 -cost_group [list $cg] > $REP_MAP/${DESIGN_NAME}.map.${cg_name}_endp.rpt.gz
}

report_timing -path_type endpoint -max_path 1000 -max_slack 0 > $REP_MAP/rt_endp_0.rpt

# ------------------------------------------------------------
# Optimization
# ------------------------------------------------------------
safe_set_db / .remove_assigns true
safe_set_db / .use_tiehilo_for_const none
safe_set_db / .syn_opt_effort $MAP_OPT_EFF

puts "INFO: Running syn_opt"
syn_opt

write_snapshot -outdir ./dbs/ -tag opt
report_summary -directory $REP_OPT

time_info OPT

safe_set_db ui_respects_preserve false
safe_set_db write_sv_port_wrapper true

foreach cg [get_db designs .cost_groups] {
    set cg_name [get_db $cg .name]
    report_timing -path_type full     -max_path 1000 -cost_group [list $cg] > $REP_OPT/${DESIGN_NAME}.opt.${cg_name}_full.rpt.gz
    report_timing -path_type endpoint -max_path 1000 -cost_group [list $cg] > $REP_OPT/${DESIGN_NAME}.opt.${cg_name}_endp.rpt.gz
    report_timing -path_type full     -max_path 1000 -cost_group [list $cg] -unconstrained > $REP_OPT/${DESIGN_NAME}.opt.${cg_name}_unconstrained.rpt.gz
}

report_timing -path_type endpoint -max_path 100000 -max_slack 0 > $REP_OPT/rt_endp0.rpt
check_design -all > $REP_OPT/${DESIGN_NAME}.check_design.rpt
check_timing_intent -verbose > $REP_OPT/check_timing.rpt
report_clock_gating > $REP_OPT/${DESIGN_NAME}.clockgating.rpt
report_power -depth 0 > $REP_OPT/${DESIGN_NAME}.power.rpt
report_gates -power > $REP_OPT/${DESIGN_NAME}.gates_power.rpt
report_gates > $REP_OPT/${DESIGN_NAME}.gates.rpt
report_dp > $REP_OPT/${DESIGN_NAME}.datapath_opt.rpt
report_messages -all > $REP_OPT/${DESIGN_NAME}.messages.rpt

set num_regs [llength [get_db insts -if {.is_flop == true}]]
set num_nets [get_db designs .num_nets]
echo "Num FFs: $num_regs\nNum Nets: $num_nets" > ${REP_OPT}/stats.opt.rpt

# ------------------------------------------------------------
# Write backend file set
# ------------------------------------------------------------
write_hdl > $OUTPUT/${DESIGN_NAME}.mapped.v
write_sdc > $OUTPUT/${DESIGN_NAME}.mapped.sdc

# Also write convenient copies
file copy -force $OUTPUT/${DESIGN_NAME}.mapped.v   ./outputs/${DESIGN_NAME}_mapped.v
file copy -force $OUTPUT/${DESIGN_NAME}.mapped.sdc ./outputs/${DESIGN_NAME}.sdc

# ------------------------------------------------------------
# Manifest
# ------------------------------------------------------------
set manifest_file "$OUTPUT/${DESIGN_NAME}.manifest.txt"
set fp [open $manifest_file "w"]

puts $fp "DESIGN_NAME: $DESIGN_NAME"
puts $fp "TOP_MODULE: $TOP_MODULE"
puts $fp "RTL_ROOT: $RTL_ROOT"
puts $fp "FILELIST: $FILELIST"
puts $fp "CLOCK_PORT: $CLOCK_PORT"
puts $fp "CLOCK_PERIOD: $CLOCK_PERIOD"
puts $fp "SYN_LIBS: $SYN_LIBS"
puts $fp "USE_PHYSICAL: $USE_PHYSICAL"
puts $fp "INSERT_CLOCK_GATING: $INSERT_CLOCK_GATING"
puts $fp "DATE: [clock format [clock seconds]]"

if {![catch {exec git -C $RTL_ROOT rev-parse HEAD} git_hash]} {
    puts $fp "RTL_GIT_COMMIT: $git_hash"
} else {
    puts $fp "RTL_GIT_COMMIT: UNKNOWN"
}

if {![catch {exec md5sum $SYN_LIBS} lib_md5]} {
    puts $fp "SYN_LIBS_MD5: $lib_md5"
} else {
    puts $fp "SYN_LIBS_MD5: UNKNOWN"
}

close $fp

puts "Final Runtime & Memory."
time_info FINAL
puts "============================================================"
puts "Synthesis Finished"
puts "DESIGN_NAME: $DESIGN_NAME"
puts "Mapped netlist: $OUTPUT/${DESIGN_NAME}.mapped.v"
puts "Manifest:       $manifest_file"
puts "============================================================"

exit
