
set_time_unit -nanoseconds
set_load_unit -femtofarads

#------------------------------
# SDC Constants
#------------------------------
set CLK_P 10;

#------------------------------
# Clock Definitions 
#------------------------------
create_clock -name CKP -period $CLK_P [get_ports clk]

#------------------------------
# Clock Properties
#------------------------------
# POSTPLACE must be set in Innovus after placement and in Tempus/Voltus before loading SDC file

if {![info exists POSTPLACE]} {
  set setupUncty     [expr 0.2 * $CLK_P]
  set holdUncty      [expr 0.1 * $CLK_P]
  set_clock_transition [expr 0.01*$CLK_P] [all_clocks]
  set_ideal_network [get_ports rst]   
} else {
  set setupUncty    0.1 
  set holdUncty     0.05
  set_propagated_clock [get_ports clk]
  reset_ideal_network  [get_ports rst]  
}

# Set intra-clock uncertainty
set_clock_uncertainty  -setup $setupUncty  [all_clocks]
set_clock_uncertainty  -hold  $holdUncty   [all_clocks]

#------------------------------
# Path Exceptions
#------------------------------
set_false_path -from [get_ports rst]

#------------------------------
# IO Timing Constraints
#------------------------------
set_driving_cell -cell INVX1 [all_inputs]
set_input_delay [expr 0.25*$CLK_P] [all_inputs -no_clocks] -clock CKP

#get_db [get_db [get_db lib_cells *INVX4] .lib_pins *A*] .capacitance
set_load 1.5 [all_outputs]
set_output_delay [expr 0.25*$CLK_P] [all_outputs] -clock CKP




