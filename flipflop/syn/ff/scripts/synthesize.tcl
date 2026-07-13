
alias h history

set DESIGN     [file rootname [file tail [file dirname [pwd]]]]
set logfile    [get_db log_file]
set hostname   [info hostname]

puts "Hostname : [info hostname]"

##############################################################################
## Preset global variables and attributes
##############################################################################
source        ../../../common/common_setup.tcl

set GEN_EFF         medium
set MAP_OPT_EFF     high

# Report directories
set REP_GEN   ./reports/generic 
set REP_MAP   ./reports/map
set REP_OPT   ./reports/opt
set REP_INC   ./reports/inc

# Run Settings
set_db max_cpus_per_server 24
set_db information_level 7 
set_db lef_stop_on_error true

# Verilog
set_db hdl_preserve_unused_registers    false  ; 
set_db hdl_preserve_unused_flop         false  ; 
set_db hdl_unconnected_value 0;
set_db hdl_create_label_for_unlabeled_generate false
set_db hdl_array_naming_style %s\[%d\] 
set_db hdl_track_filename_row_col true
set_db ungroup_separator /
set_db hdl_vhdl_read_version 2008
set_db write_vlog_unconnected_port_style none
set_db print_ports_nets_preserved_for_cb true

# Mapping
set_db use_scan_seqs_for_non_dft false
set_db init_blackbox_for_undefined false
set_db ultra_global_mapping true 
set_db / .auto_ungroup none

# Power
set_db lp_insert_clock_gating true 
set_db lp_power_analysis_effort high
set_db lp_power_unit mW 
set_db leakage_power_effort medium
set_db design_power_effort low
set_db opt_leakage_to_dynamic_ratio 0.5

# SDC 
set_db detailed_sdc_messages true

###############################################################
## Library setup
###############################################################

set SYN_LIBS  [concat $STD(slow_vdd1v0)]
read_libs $SYN_LIBS

read_physical -lef [concat $PDK(lef) $STD(lef)]

## Provide either cap_table_file or the qrc_tech_file
read_qrc $PDK(qrc_rcworst)

# M2-M9
set_db number_of_routing_layers 8 

####################################################################
## Load Design
####################################################################

source ../scripts/read_design.tcl

elaborate ${DESIGN}  

#rename_object [get_db designs] $DESIGN 

uniquify  $DESIGN -verbose

time_info Elaboration

puts "Num FFs: [llength [get_db insts -if {.is_flop == true}]]"

check_design -unresolved
#
check_design -all > $REP_GEN/${DESIGN}.check_design.rpt

set SYNTH(BlackBox)   [llength [get_db design:$DESIGN .blackboxes]]
set SYNTH(Unresolved) [llength [get_db hinsts -if {.unresolved==true}]]
if {$SYNTH(BlackBox) || $SYNTH(Unresolved)} {echo "\n\tUnresolved references or blackboxes in design....exit\n"; exit}

####################################################################
## Constraints Setup
####################################################################
set_units -time ns
set_units -capacitance fF

read_sdc ../../../source/constraints/${DESIGN}.sdc

echo $::dc::sdc_failed_commands > reports/sdc_failed_commands.rpt

foreach excep [get_db exceptions ] {
   echo "[get_db $excep  .name] \t [get_db $excep  .exception_type] \t [get_db $excep  .priority]" 
   echo "[get_db $excep  .name] \t [get_db $excep  .exception_type] \t [get_db $excep  .priority]" > ./reports/exceptions.rpt
}

check_timing_intent -verbose > $REP_GEN/check_timing.rpt

###################################################################################
## Define cost groups (clock-clock, clock-output, input-clock, input-output)
###################################################################################

define_cost_group -name I2O -design $DESIGN
define_cost_group -name I2C -design $DESIGN
define_cost_group -name C2O -design $DESIGN
define_cost_group -name C2C -design $DESIGN
path_group -from [all_registers] -to [all_registers] -group C2C -name C2C
path_group -from [all_registers] -to [all_outputs]   -group C2O -name C2O
path_group -from [all_inputs]    -to [all_registers] -group I2C -name I2C
path_group -from [all_inputs]  -to [all_outputs] -group I2O -name I2O

#######################################################################################
## Leakage/Dynamic power/Clock Gating setup.
#######################################################################################
## read_vcd <VCD file name>

####################################################################################################
## Synthesizing to generic 
####################################################################################################
set_db / .syn_generic_effort $GEN_EFF

syn_generic

time_info GENERIC

report_dp                  > $REP_GEN/${DESIGN}.generic.datapath.rpt
write_snapshot -outdir       ./dbs/ -tag generic
report_summary -directory    $REP_GEN 

####################################################################################################
## Synthesizing to gates
####################################################################################################
set_db / .syn_map_effort $MAP_OPT_EFF

syn_map

time_info MAPPED

write_snapshot -outdir      ./dbs/   -tag map
report_summary -directory   $REP_MAP 

set num_regs [llength [get_db insts    -if {.is_flop == true}]]
set num_nets [get_db designs  .num_nets]

echo "  Num FFs:  $num_regs\n Num Nets: $num_nets" >  ${REP_MAP}/stats.map.rpt 

foreach cg [get_db designs .cost_groups] {
      report_timing -path_type full     -max_path 1000 -cost_group [list $cg] > $REP_MAP/${DESIGN}.map.[get_db $cg .name]_full.rpt.gz
      report_timing -path_type endpoint -max_path 1000 -cost_group [list $cg] > $REP_MAP/${DESIGN}.map.[get_db $cg .name]_endp.rpt.gz
}

report_timing -path_type endpoint -max_path 1000 -max_slack 0 > $REP_MAP/rt_endp_0.rpt

#######################################################################################################
## Optimize Netlist
#######################################################################################################
set_db / .remove_assigns true 
set_db / .use_tiehilo_for_const none 
set_db / .syn_opt_effort $MAP_OPT_EFF

syn_opt

write_snapshot -outdir    ./dbs/   -tag opt
report_summary -directory   $REP_OPT 

time_info OPT

set_db ui_respects_preserve false
set_db write_sv_port_wrapper true

foreach cg [get_db designs .cost_groups] {
      report_timing -path_type full     -max_path 1000 -cost_group [list $cg]                > $REP_OPT/${DESIGN}.opt.[get_db $cg .name]_full.rpt.gz
      report_timing -path_type endpoint -max_path 1000 -cost_group [list $cg]                > $REP_OPT/${DESIGN}.opt.[get_db $cg .name]_endp.rpt.gz
      report_timing -path_type full     -max_path 1000 -cost_group [list $cg] -unconstrained > $REP_OPT/${DESIGN}.opt.[get_db $cg .name]_endp.rpt.gz
}

report_timing -path_type endpoint -max_path 100000 -max_slack 0 > $REP_OPT/rt_endp0.rpt
check_design -all > $REP_OPT/${DESIGN}.check_design
check_timing_intent -verbose > $REP_OPT/check_timing.rpt
report_clock_gating     > $REP_OPT/${DESIGN}.clockgating.rpt
report_power -depth 0   > $REP_OPT/${DESIGN}.power.rpt
report_gates -power     > $REP_OPT/${DESIGN}.gates_power.rpt
report_gates            > $REP_OPT/${DESIGN}.gates.rpt
report_dp               > $REP_OPT/${DESIGN}.datapath_opt.rpt
report_messages -all    > $REP_OPT/${DESIGN}.messages.rpt

set num_regs [llength [get_db insts    -if {.is_flop == true}]]
set num_nets [get_db designs  .num_nets]
echo "  Num FFs:  $num_regs\n Num Nets: $num_nets" >  ${REP_OPT}/stats.opt.rpt 

######################################################################################################
## write backend file set (verilog, SDC, config, etc.)
######################################################################################################
set OUTPUT    ./results/${DESIGN}.SYN

write_hdl   > $OUTPUT/${DESIGN}.mapped.v

puts "Final Runtime & Memory."
time_info FINAL
puts "============================"
puts "Synthesis Finished ........."
puts "============================"
