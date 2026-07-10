# ============================================================
# Common Cadence Genus synthesis flow
#
# Modes:
#   Batch synthesis:
#     RUN_SYNTH      = true
#     EXIT_AFTER_RUN = true
## ============================================================
# Common Cadence Genus synthesis flow
#
# Modes:
#   Batch synthesis:
#       RUN_SYNTH       = true
#       CHECK_ONLY      = false
#       EXIT_AFTER_RUN  = true
#
#   GUI load:
#       RUN_SYNTH       = false
#       CHECK_ONLY      = false
#       EXIT_AFTER_RUN  = false
#
#   HDL/elaboration check:
#       RUN_SYNTH       = false
#       CHECK_ONLY      = true
#       EXIT_AFTER_RUN  = true
#
# Required from the design config.tcl:
#   DESIGN_NAME
#   TOP_MODULE
#   RTL_ROOT
#   SDC_FILE
#   CLOCK_PORT
#   CLOCK_PERIOD
#
# HDL inputs can be supplied through:
#   FILELIST                 legacy single filelist
#   HDL_FILELISTS            ordered list of filelists
#   HDL_PACKAGE_FILES        ordered package source list
#   HDL_RTL_FILES            ordered RTL source list
#   HDL_INCLUDE_DIRS         include/search directories
#   HDL_DEFINES              global SystemVerilog macros
#   PRE_READ_TCL             optional hook before read_hdl
#   POST_READ_TCL            optional hook after read_hdl
#
# Required from the selected common/pdk/<PDK_NAME>.tcl:
#   SYN_LIBS
# ============================================================

# Load the HDL helper automatically when an older benchmark entry
# script sources only this common file.  This preserves compatibility
# with existing benchmark syn/scripts while the benchmark-specific
# files are migrated later.
if {[llength [info commands flow_collect_hdl_configuration]] == 0} {
    if {![info exists ::env(ASIC_FLOW_HOME)] ||
        [string trim $::env(ASIC_FLOW_HOME)] eq ""} {
        puts "ERROR: ASIC_FLOW_HOME is not set; cannot locate genus_helpers.tcl"
        exit 1
    }

    set helper_script [file normalize \
        "$::env(ASIC_FLOW_HOME)/common/syn/genus_helpers.tcl"]

    if {![file isfile $helper_script]} {
        puts "ERROR: Genus helper script does not exist: $helper_script"
        exit 1
    }

    source $helper_script
}

catch {alias h history}

set hostname [info hostname]
puts "Hostname : $hostname"

# ------------------------------------------------------------
# Flow mode defaults
# ------------------------------------------------------------
if {![info exists RUN_SYNTH]} {
    set RUN_SYNTH true
}
if {![info exists CHECK_ONLY]} {
    set CHECK_ONLY false
}
if {![info exists EXIT_AFTER_RUN]} {
    set EXIT_AFTER_RUN true
}
if {![info exists GUI_MODE]} {
    set GUI_MODE false
}

# ------------------------------------------------------------
# Defaults from local config.tcl
# ------------------------------------------------------------
if {![info exists GEN_EFF]} {
    set GEN_EFF medium
}
if {![info exists MAP_OPT_EFF]} {
    set MAP_OPT_EFF high
}
if {![info exists NUM_CPUS]} {
    set NUM_CPUS 8
}
if {![info exists USE_PHYSICAL]} {
    set USE_PHYSICAL false
}
if {![info exists INSERT_CLOCK_GATING]} {
    set INSERT_CLOCK_GATING false
}
if {![info exists PRE_READ_TCL]} {
    set PRE_READ_TCL ""
}
if {![info exists POST_READ_TCL]} {
    set POST_READ_TCL ""
}
if {![info exists PDK_NAME] || [string trim $PDK_NAME] eq ""} {
    set PDK_NAME nangate45
}

# ------------------------------------------------------------
# Common helper procedures
# ------------------------------------------------------------
proc safe_set_db {args} {
    if {[catch {eval set_db $args} msg]} {
        puts "WARNING: set_db $args failed: $msg"
    }
}

proc flow_fatal {msg} {
    global EXIT_AFTER_RUN

    puts ""
    puts "ERROR: $msg"
    puts ""

    if {$EXIT_AFTER_RUN} {
        exit 1
    } else {
        return -code error $msg
    }
}

proc flow_require_config {variable_name} {
    if {![uplevel 1 [list info exists $variable_name]]} {
        error "Required configuration variable is missing: $variable_name"
    }

    set value [uplevel 1 [list set $variable_name]]
    if {[string trim $value] eq ""} {
        error "Required configuration variable is empty: $variable_name"
    }
}

proc flow_write_manifest {manifest_file phase} {
    global DESIGN_NAME
    global TOP_MODULE
    global RTL_ROOT
    global SDC_FILE
    global CLOCK_PORT
    global CLOCK_PERIOD
    global SYN_LIBS
    global PDK_NAME
    global GEN_EFF
    global MAP_OPT_EFF
    global NUM_CPUS
    global USE_PHYSICAL
    global INSERT_CLOCK_GATING
    global RUN_SYNTH
    global CHECK_ONLY
    global EXIT_AFTER_RUN
    global GUI_MODE
    global HDL_FILELISTS
    global HDL_PACKAGE_FILES
    global HDL_RTL_FILES
    global HDL_INCLUDE_DIRS
    global HDL_DEFINES
    global PRE_READ_TCL
    global POST_READ_TCL

    file mkdir [file dirname $manifest_file]
    set fp [open $manifest_file "w"]

    puts $fp "PHASE: $phase"
    puts $fp "DESIGN_NAME: $DESIGN_NAME"
    puts $fp "TOP_MODULE: $TOP_MODULE"
    puts $fp "RTL_ROOT: $RTL_ROOT"
    puts $fp "SDC_FILE: $SDC_FILE"
    puts $fp "CLOCK_PORT: $CLOCK_PORT"
    puts $fp "CLOCK_PERIOD: $CLOCK_PERIOD"
    puts $fp "PDK_NAME: $PDK_NAME"
    puts $fp "SYN_LIBS: $SYN_LIBS"
    puts $fp "GEN_EFF: $GEN_EFF"
    puts $fp "MAP_OPT_EFF: $MAP_OPT_EFF"
    puts $fp "NUM_CPUS: $NUM_CPUS"
    puts $fp "USE_PHYSICAL: $USE_PHYSICAL"
    puts $fp "INSERT_CLOCK_GATING: $INSERT_CLOCK_GATING"
    puts $fp "RUN_SYNTH: $RUN_SYNTH"
    puts $fp "CHECK_ONLY: $CHECK_ONLY"
    puts $fp "EXIT_AFTER_RUN: $EXIT_AFTER_RUN"
    puts $fp "GUI_MODE: $GUI_MODE"
    puts $fp "PRE_READ_TCL: $PRE_READ_TCL"
    puts $fp "POST_READ_TCL: $POST_READ_TCL"
    puts $fp "DATE: [clock format [clock seconds]]"

    puts $fp ""
    puts $fp "HDL_FILELISTS:"
    if {[llength $HDL_FILELISTS] == 0} {
        puts $fp "  <none>"
    } else {
        foreach item $HDL_FILELISTS {
            puts $fp "  $item"
        }
    }

    puts $fp ""
    puts $fp "HDL_PACKAGE_FILES:"
    if {[llength $HDL_PACKAGE_FILES] == 0} {
        puts $fp "  <none>"
    } else {
        foreach item $HDL_PACKAGE_FILES {
            puts $fp "  $item"
        }
    }

    puts $fp ""
    puts $fp "HDL_RTL_FILES:"
    if {[llength $HDL_RTL_FILES] == 0} {
        puts $fp "  <none>"
    } else {
        foreach item $HDL_RTL_FILES {
            puts $fp "  $item"
        }
    }

    puts $fp ""
    puts $fp "HDL_INCLUDE_DIRS:"
    if {[llength $HDL_INCLUDE_DIRS] == 0} {
        puts $fp "  <none>"
    } else {
        foreach item $HDL_INCLUDE_DIRS {
            puts $fp "  $item"
        }
    }

    puts $fp ""
    puts $fp "HDL_DEFINES:"
    if {[llength $HDL_DEFINES] == 0} {
        puts $fp "  <none>"
    } else {
        foreach item $HDL_DEFINES {
            puts $fp "  $item"
        }
    }

    if {![catch {exec git -C $RTL_ROOT rev-parse HEAD} git_hash]} {
        puts $fp ""
        puts $fp "RTL_GIT_COMMIT: $git_hash"
    } else {
        puts $fp ""
        puts $fp "RTL_GIT_COMMIT: UNKNOWN"
    }

    puts $fp ""
    puts $fp "LIBRARY_CHECKSUMS:"
    foreach library_file $SYN_LIBS {
        if {![catch {exec md5sum $library_file} library_md5]} {
            puts $fp "  $library_md5"
        } else {
            puts $fp "  UNKNOWN  $library_file"
        }
    }

    close $fp
    return $manifest_file
}

# ------------------------------------------------------------
# Validate required configuration
# ------------------------------------------------------------
if {[catch {
    foreach required_variable {
        DESIGN_NAME
        TOP_MODULE
        RTL_ROOT
        SDC_FILE
        CLOCK_PORT
        CLOCK_PERIOD
        SYN_LIBS
    } {
        flow_require_config $required_variable
    }

    if {![file isdirectory $RTL_ROOT]} {
        error "RTL_ROOT does not exist: $RTL_ROOT"
    }

    flow_collect_hdl_configuration
} validation_error]} {
    flow_fatal $validation_error
}

# ------------------------------------------------------------
# Directory setup
# Genus is launched inside syn/runs/run_xxx/
# ------------------------------------------------------------
set REP_GEN ./reports/generic
set REP_MAP ./reports/map
set REP_OPT ./reports/opt
set REP_GUI ./reports/gui
set OUTPUT  ./results/${DESIGN_NAME}.SYN

file mkdir logs
file mkdir reports
file mkdir $REP_GEN
file mkdir $REP_MAP
file mkdir $REP_OPT
file mkdir $REP_GUI
file mkdir results
file mkdir $OUTPUT
file mkdir outputs
file mkdir dbs
file mkdir work
file mkdir fv

puts "============================================================"
puts "INFO: Starting Genus common synthesis flow"
puts "INFO: DESIGN_NAME         = $DESIGN_NAME"
puts "INFO: TOP_MODULE          = $TOP_MODULE"
puts "INFO: RTL_ROOT            = $RTL_ROOT"
puts "INFO: SDC_FILE            = $SDC_FILE"
puts "INFO: CLOCK_PORT          = $CLOCK_PORT"
puts "INFO: CLOCK_PERIOD        = $CLOCK_PERIOD"
puts "INFO: PDK_NAME            = $PDK_NAME"
puts "INFO: SYN_LIBS            = $SYN_LIBS"
puts "INFO: GEN_EFF             = $GEN_EFF"
puts "INFO: MAP_OPT_EFF         = $MAP_OPT_EFF"
puts "INFO: NUM_CPUS            = $NUM_CPUS"
puts "INFO: USE_PHYSICAL        = $USE_PHYSICAL"
puts "INFO: INSERT_CLOCK_GATING = $INSERT_CLOCK_GATING"
puts "INFO: RUN_SYNTH           = $RUN_SYNTH"
puts "INFO: CHECK_ONLY          = $CHECK_ONLY"
puts "INFO: EXIT_AFTER_RUN      = $EXIT_AFTER_RUN"
puts "INFO: GUI_MODE            = $GUI_MODE"
puts "INFO: HDL_FILELISTS       = $HDL_FILELISTS"
puts "INFO: HDL_PACKAGE_FILES   = $HDL_PACKAGE_FILES"
puts "INFO: HDL_RTL_FILES       = $HDL_RTL_FILES"
puts "INFO: HDL_INCLUDE_DIRS    = $HDL_INCLUDE_DIRS"
puts "INFO: HDL_DEFINES         = $HDL_DEFINES"
puts "============================================================"

# ------------------------------------------------------------
# Genus settings
# ------------------------------------------------------------
safe_set_db max_cpus_per_server $NUM_CPUS
safe_set_db information_level 7
safe_set_db lef_stop_on_error true
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
safe_set_db use_scan_seqs_for_non_dft false
safe_set_db init_blackbox_for_undefined false
safe_set_db ultra_global_mapping true
safe_set_db / .auto_ungroup none
safe_set_db lp_insert_clock_gating $INSERT_CLOCK_GATING
safe_set_db lp_power_analysis_effort high
safe_set_db lp_power_unit mW
safe_set_db leakage_power_effort medium
safe_set_db design_power_effort low
safe_set_db opt_leakage_to_dynamic_ratio 0.5
safe_set_db detailed_sdc_messages true

# ------------------------------------------------------------
# Read timing libraries
# ------------------------------------------------------------
foreach library_file $SYN_LIBS {
    if {![file isfile $library_file]} {
        flow_fatal "SYN_LIBS file does not exist: $library_file"
    }
}

puts "INFO: Reading timing libraries using read_libs"
if {[catch {read_libs $SYN_LIBS} library_error]} {
    flow_fatal "Library read failed: $library_error"
}

# Optional physical-aware synthesis
if {$USE_PHYSICAL} {
    if {[info exists PDK(lef)] && [string trim $PDK(lef)] ne ""} {
        puts "INFO: Reading LEF files"
        if {[catch {read_physical -lef $PDK(lef)} physical_error]} {
            flow_fatal "LEF read failed: $physical_error"
        }
    } else {
        puts "WARNING: USE_PHYSICAL is true, but PDK(lef) is empty"
    }

    if {[info exists PDK(qrc_rcworst)] &&
        [file isfile $PDK(qrc_rcworst)]} {
        puts "INFO: Reading QRC file: $PDK(qrc_rcworst)"
        if {[catch {read_qrc $PDK(qrc_rcworst)} qrc_error]} {
            flow_fatal "QRC read failed: $qrc_error"
        }
    } else {
        puts "WARNING: No valid QRC file found. Skipping read_qrc."
    }
}

# ------------------------------------------------------------
# Optional pre-read hook
# ------------------------------------------------------------
if {[catch {
    flow_source_optional $PRE_READ_TCL "pre-read Tcl hook"
} pre_read_error]} {
    flow_fatal $pre_read_error
}

# ------------------------------------------------------------
# Read HDL
# ------------------------------------------------------------
if {[catch {
    flow_read_all_hdl
} hdl_error]} {
    flow_fatal "HDL read failed: $hdl_error"
}

# ------------------------------------------------------------
# Optional post-read hook
# ------------------------------------------------------------
if {[catch {
    flow_source_optional $POST_READ_TCL "post-read Tcl hook"
} post_read_error]} {
    flow_fatal $post_read_error
}

# ------------------------------------------------------------
# Elaborate
# ------------------------------------------------------------
puts "INFO: Elaborating top module: $TOP_MODULE"
if {[catch {elaborate $TOP_MODULE} elaborate_error]} {
    flow_fatal "Elaboration failed: $elaborate_error"
}

catch {uniquify $TOP_MODULE -verbose}
catch {time_info Elaboration}

set num_ffs_elab 0
catch {
    set num_ffs_elab [llength [get_db insts -if {.is_flop == true}]]
}
puts "INFO: Num FFs after elaboration: $num_ffs_elab"

check_design -unresolved
check_design -all > $REP_GEN/${DESIGN_NAME}.check_design.rpt

set SYNTH(BlackBox) 0
set SYNTH(Unresolved) 0
catch {
    set SYNTH(BlackBox) \
        [llength [get_db design:$TOP_MODULE .blackboxes]]
}
catch {
    set SYNTH(Unresolved) \
        [llength [get_db hinsts -if {.unresolved == true}]]
}

puts "INFO: BlackBox count  = $SYNTH(BlackBox)"
puts "INFO: Unresolved count = $SYNTH(Unresolved)"

if {$SYNTH(BlackBox) || $SYNTH(Unresolved)} {
    flow_fatal "Unresolved references or blackboxes found. Check $REP_GEN/${DESIGN_NAME}.check_design.rpt"
}

# ------------------------------------------------------------
# Constraints
# ------------------------------------------------------------
set_units -time ns
set_units -capacitance fF

if {[file isfile $SDC_FILE]} {
    puts "INFO: Reading SDC file: $SDC_FILE"
    if {[catch {read_sdc $SDC_FILE} sdc_error]} {
        flow_fatal "SDC read failed: $sdc_error"
    }
} else {
    puts "WARNING: SDC file not found: $SDC_FILE"
    puts "WARNING: Creating a basic clock on $CLOCK_PORT"

    if {[catch {
        create_clock -name $CLOCK_PORT -period $CLOCK_PERIOD \
            [get_ports $CLOCK_PORT]
    } clock_error]} {
        flow_fatal "Unable to create fallback clock: $clock_error"
    }
}

if {[info exists ::dc::sdc_failed_commands]} {
    echo $::dc::sdc_failed_commands \
        > reports/sdc_failed_commands.rpt
}

set fp_exceptions [open "./reports/exceptions.rpt" "w"]
if {![catch {set all_exceptions [get_db exceptions]} exception_error]} {
    foreach exception $all_exceptions {
        set line "[get_db $exception .name] \t [get_db $exception .exception_type] \t [get_db $exception .priority]"
        puts $line
        puts $fp_exceptions $line
    }
} else {
    puts "WARNING: Could not query exceptions: $exception_error"
}
close $fp_exceptions

check_timing_intent -verbose > $REP_GEN/check_timing.rpt

# ------------------------------------------------------------
# Check-only mode stops here
# ------------------------------------------------------------
if {$CHECK_ONLY} {
    catch {
        report_messages -all \
            > $REP_GEN/${DESIGN_NAME}.check.messages.rpt
    }

    set check_manifest \
        "$OUTPUT/${DESIGN_NAME}.check.manifest.txt"
    flow_write_manifest $check_manifest "hdl_elaboration_check"
    file copy -force $check_manifest \
        "./outputs/${DESIGN_NAME}_check_manifest.txt"

    puts "============================================================"
    puts "INFO: HDL/elaboration/constraint check completed"
    puts "INFO: DESIGN_NAME = $DESIGN_NAME"
    puts "INFO: TOP_MODULE  = $TOP_MODULE"
    puts "INFO: Stopping before syn_generic"
    puts "INFO: Manifest: $check_manifest"
    puts "============================================================"

    if {$EXIT_AFTER_RUN} {
        exit
    } else {
        return
    }
}

# ------------------------------------------------------------
# Cost groups
# ------------------------------------------------------------
catch {define_cost_group -name I2O -design $TOP_MODULE}
catch {define_cost_group -name I2C -design $TOP_MODULE}
catch {define_cost_group -name C2O -design $TOP_MODULE}
catch {define_cost_group -name C2C -design $TOP_MODULE}

catch {
    path_group -from [all_registers] -to [all_registers] \
        -group C2C -name C2C
}
catch {
    path_group -from [all_registers] -to [all_outputs] \
        -group C2O -name C2O
}
catch {
    path_group -from [all_inputs] -to [all_registers] \
        -group I2C -name I2C
}
catch {
    path_group -from [all_inputs] -to [all_outputs] \
        -group I2O -name I2O
}

# ------------------------------------------------------------
# GUI mode stops here
# ------------------------------------------------------------
if {!$RUN_SYNTH} {
    puts "============================================================"
    puts "INFO: RUN_SYNTH is false."
    puts "INFO: Library, HDL, elaboration, constraints, and cost"
    puts "INFO: groups are loaded."
    puts "INFO: Stopping before syn_generic / syn_map / syn_opt."
    puts ""
    puts "INFO: Run the remaining flow with:"
    puts "INFO:   source $SCRIPTS_DIR/gui_write.tcl"
    puts ""
    puts "INFO: This script intentionally does not exit Genus."
    puts "============================================================"

    catch {report_summary -directory $REP_GUI}
    catch {
        report_timing -path_type full -max_path 20 \
            > $REP_GUI/${DESIGN_NAME}.gui.initial_timing.rpt
    }
    catch {
        report_gates \
            > $REP_GUI/${DESIGN_NAME}.gui.initial_gates.rpt
    }
    return
}

# ------------------------------------------------------------
# Generic synthesis
# ------------------------------------------------------------
safe_set_db / .syn_generic_effort $GEN_EFF
puts "INFO: Running syn_generic"
syn_generic
catch {time_info GENERIC}

report_dp > $REP_GEN/${DESIGN_NAME}.generic.datapath.rpt
write_snapshot -outdir ./dbs/ -tag generic
report_summary -directory $REP_GEN

# ------------------------------------------------------------
# Mapping
# ------------------------------------------------------------
safe_set_db / .syn_map_effort $MAP_OPT_EFF
puts "INFO: Running syn_map"
syn_map
catch {time_info MAPPED}

write_snapshot -outdir ./dbs/ -tag map
report_summary -directory $REP_MAP

set num_regs 0
set num_nets 0
catch {
    set num_regs [llength [get_db insts -if {.is_flop == true}]]
}
catch {
    set num_nets [get_db designs .num_nets]
}
echo "Num FFs: $num_regs\nNum Nets: $num_nets" \
    > ${REP_MAP}/stats.map.rpt

foreach cost_group [get_db designs .cost_groups] {
    set cost_group_name [get_db $cost_group .name]

    report_timing -path_type full -max_path 1000 \
        -cost_group [list $cost_group] \
        > $REP_MAP/${DESIGN_NAME}.map.${cost_group_name}_full.rpt.gz

    report_timing -path_type endpoint -max_path 1000 \
        -cost_group [list $cost_group] \
        > $REP_MAP/${DESIGN_NAME}.map.${cost_group_name}_endp.rpt.gz
}

report_timing -path_type endpoint -max_path 1000 -max_slack 0 \
    > $REP_MAP/rt_endp_0.rpt

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
catch {time_info OPT}

safe_set_db ui_respects_preserve false
safe_set_db write_sv_port_wrapper true

foreach cost_group [get_db designs .cost_groups] {
    set cost_group_name [get_db $cost_group .name]

    report_timing -path_type full -max_path 1000 \
        -cost_group [list $cost_group] \
        > $REP_OPT/${DESIGN_NAME}.opt.${cost_group_name}_full.rpt.gz

    report_timing -path_type endpoint -max_path 1000 \
        -cost_group [list $cost_group] \
        > $REP_OPT/${DESIGN_NAME}.opt.${cost_group_name}_endp.rpt.gz

    report_timing -path_type full -max_path 1000 \
        -cost_group [list $cost_group] -unconstrained \
        > $REP_OPT/${DESIGN_NAME}.opt.${cost_group_name}_unconstrained.rpt.gz
}

report_timing -path_type endpoint -max_path 100000 -max_slack 0 \
    > $REP_OPT/rt_endp0.rpt

check_design -all > $REP_OPT/${DESIGN_NAME}.check_design.rpt
check_timing_intent -verbose > $REP_OPT/check_timing.rpt
report_clock_gating > $REP_OPT/${DESIGN_NAME}.clockgating.rpt
report_power -depth 0 > $REP_OPT/${DESIGN_NAME}.power.rpt
report_gates -power > $REP_OPT/${DESIGN_NAME}.gates_power.rpt
report_gates > $REP_OPT/${DESIGN_NAME}.gates.rpt
report_dp > $REP_OPT/${DESIGN_NAME}.datapath_opt.rpt
report_messages -all > $REP_OPT/${DESIGN_NAME}.messages.rpt

set num_regs 0
set num_nets 0
catch {
    set num_regs [llength [get_db insts -if {.is_flop == true}]]
}
catch {
    set num_nets [get_db designs .num_nets]
}
echo "Num FFs: $num_regs\nNum Nets: $num_nets" \
    > ${REP_OPT}/stats.opt.rpt

# ------------------------------------------------------------
# Write backend file set
# ------------------------------------------------------------
write_hdl > $OUTPUT/${DESIGN_NAME}.mapped.v
write_sdc > $OUTPUT/${DESIGN_NAME}.mapped.sdc

file copy -force $OUTPUT/${DESIGN_NAME}.mapped.v \
    ./outputs/${DESIGN_NAME}_mapped.v
file copy -force $OUTPUT/${DESIGN_NAME}.mapped.sdc \
    ./outputs/${DESIGN_NAME}.sdc

# ------------------------------------------------------------
# Manifest
# This is the section that records the exact HDL inputs,
# defines, include directories, RTL commit, library checksum,
# PDK, flow mode, and synthesis effort for reproducibility.
# ------------------------------------------------------------
set manifest_file "$OUTPUT/${DESIGN_NAME}.manifest.txt"
flow_write_manifest $manifest_file "mapped_synthesis"
file copy -force $manifest_file \
    "./outputs/${DESIGN_NAME}_manifest.txt"

puts "Final Runtime & Memory."
catch {time_info FINAL}

puts "============================================================"
puts "Synthesis Finished"
puts "DESIGN_NAME: $DESIGN_NAME"
puts "Mapped netlist: $OUTPUT/${DESIGN_NAME}.mapped.v"
puts "Manifest: $manifest_file"
puts "============================================================"

if {$EXIT_AFTER_RUN} {
    exit
} else {
    return
}

#   GUI load:
#     RUN_SYNTH      = false
#     EXIT_AFTER_RUN = false
#
# Required from local config.tcl:
#   DESIGN_NAME
#   TOP_MODULE
#   RTL_ROOT
#   FILELIST
#   SDC_FILE
#   CLOCK_PORT
#   CLOCK_PERIOD
#
# Required from common/pdk/nangate45.tcl:
#   SYN_LIBS
# ============================================================
if {![info exists CHECK_ONLY]} {
    set CHECK_ONLY false
}


foreach required_var {
    DESIGN_NAME
    TOP_MODULE
    RTL_ROOT
    CLOCK_PORT
    CLOCK_PERIOD
    SYN_LIBS
} {
    if {![info exists $required_var] ||
        [string trim [set $required_var]] eq ""} {
        flow_fatal "Required variable is missing: $required_var"
    }
}

if {![file isdirectory $RTL_ROOT]} {
    flow_fatal "RTL_ROOT does not exist: $RTL_ROOT"
}

catch {alias h history}

set hostname [info hostname]
puts "Hostname : $hostname"

# ------------------------------------------------------------
# Flow mode defaults
# ------------------------------------------------------------
if {![info exists RUN_SYNTH]}      { set RUN_SYNTH true }
if {![info exists EXIT_AFTER_RUN]} { set EXIT_AFTER_RUN true }
if {![info exists GUI_MODE]}       { set GUI_MODE false }

# ------------------------------------------------------------
# Defaults from local config.tcl
# ------------------------------------------------------------
if {![info exists GEN_EFF]}      { set GEN_EFF medium }
if {![info exists MAP_OPT_EFF]}  { set MAP_OPT_EFF high }
if {![info exists NUM_CPUS]}     { set NUM_CPUS 8 }
if {![info exists USE_PHYSICAL]} { set USE_PHYSICAL false }
if {![info exists INSERT_CLOCK_GATING]} { set INSERT_CLOCK_GATING false }

# ------------------------------------------------------------
# Helper procedures
# ------------------------------------------------------------
proc safe_set_db {args} {
    if {[catch {eval set_db $args} msg]} {
        puts "WARNING: set_db $args failed: $msg"
    }
}

proc flow_fatal {msg} {
    global EXIT_AFTER_RUN
    puts ""
    puts "ERROR: $msg"
    puts ""

    if {$EXIT_AFTER_RUN} {
        exit 1
    } else {
        return -code error $msg
    }
}

# ------------------------------------------------------------
# Directory setup
# All generated files should go under RUN_DIR.
# Genus should be launched from syn/runs/run_xxx/.
# ------------------------------------------------------------

if {![info exists RUN_DIR]} {
    set RUN_DIR [file normalize [pwd]]
}

if {![info exists LOG_DIR]} {
    set LOG_DIR "$RUN_DIR/logs"
}

if {![info exists REPORT_DIR]} {
    set REPORT_DIR "$RUN_DIR/reports"
}

if {![info exists RESULT_DIR]} {
    set RESULT_DIR "$RUN_DIR/results"
}

if {![info exists OUTPUT_DIR]} {
    set OUTPUT_DIR "$RUN_DIR/outputs"
}

if {![info exists DB_DIR]} {
    set DB_DIR "$RUN_DIR/dbs"
}

if {![info exists WORK_DIR]} {
    set WORK_DIR "$RUN_DIR/work"
}

if {![info exists FV_DIR]} {
    set FV_DIR "$RUN_DIR/fv"
}

set REP_GEN "$REPORT_DIR/generic"
set REP_MAP "$REPORT_DIR/map"
set REP_OPT "$REPORT_DIR/opt"
set REP_GUI "$REPORT_DIR/gui"
set OUTPUT  "$RESULT_DIR/${DESIGN_NAME}.SYN"

foreach d [list \
    $LOG_DIR \
    $REPORT_DIR \
    $REP_GEN \
    $REP_MAP \
    $REP_OPT \
    $REP_GUI \
    $RESULT_DIR \
    $OUTPUT \
    $OUTPUT_DIR \
    $DB_DIR \
    $WORK_DIR \
    $FV_DIR \
] {
    file mkdir $d
}

puts "INFO: RUN_DIR    = $RUN_DIR"
puts "INFO: LOG_DIR    = $LOG_DIR"
puts "INFO: REPORT_DIR = $REPORT_DIR"
puts "INFO: RESULT_DIR = $RESULT_DIR"
puts "INFO: OUTPUT_DIR = $OUTPUT_DIR"
puts "INFO: DB_DIR     = $DB_DIR"
puts "INFO: WORK_DIR   = $WORK_DIR"

puts "============================================================"
puts "INFO: Starting Genus common synthesis flow"
puts "INFO: DESIGN_NAME         = $DESIGN_NAME"
puts "INFO: TOP_MODULE          = $TOP_MODULE"
puts "INFO: RTL_ROOT            = $RTL_ROOT"
puts "INFO: FILELIST            = $FILELIST"
puts "INFO: SDC_FILE            = $SDC_FILE"
puts "INFO: CLOCK_PORT          = $CLOCK_PORT"
puts "INFO: CLOCK_PERIOD        = $CLOCK_PERIOD"
puts "INFO: SYN_LIBS            = $SYN_LIBS"
puts "INFO: GEN_EFF             = $GEN_EFF"
puts "INFO: MAP_OPT_EFF         = $MAP_OPT_EFF"
puts "INFO: USE_PHYSICAL        = $USE_PHYSICAL"
puts "INFO: INSERT_CLOCK_GATING = $INSERT_CLOCK_GATING"
puts "INFO: RUN_SYNTH           = $RUN_SYNTH"
puts "INFO: EXIT_AFTER_RUN      = $EXIT_AFTER_RUN"
puts "INFO: GUI_MODE            = $GUI_MODE"
puts "============================================================"

# ------------------------------------------------------------
# Genus settings
# ------------------------------------------------------------
safe_set_db max_cpus_per_server $NUM_CPUS
safe_set_db information_level 7
safe_set_db lef_stop_on_error true

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

safe_set_db use_scan_seqs_for_non_dft false
safe_set_db init_blackbox_for_undefined false
safe_set_db ultra_global_mapping true
safe_set_db / .auto_ungroup none

safe_set_db lp_insert_clock_gating $INSERT_CLOCK_GATING
safe_set_db lp_power_analysis_effort high
safe_set_db lp_power_unit mW
safe_set_db leakage_power_effort medium
safe_set_db design_power_effort low
safe_set_db opt_leakage_to_dynamic_ratio 0.5

safe_set_db detailed_sdc_messages true

# ------------------------------------------------------------
# Read library
# ------------------------------------------------------------
if {![file exists $SYN_LIBS]} {
    flow_fatal "SYN_LIBS does not exist: $SYN_LIBS"
}

puts "INFO: Reading timing libraries using read_libs"
read_libs $SYN_LIBS

# Optional physical-aware synthesis
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
        puts "WARNING: No valid QRC file found. Skipping read_qrc."
    }
}

# ------------------------------------------------------------
# Optional pre-read hook
# ------------------------------------------------------------
if {![info exists PRE_READ_TCL]} {
    set PRE_READ_TCL ""
}

if {![info exists POST_READ_TCL]} {
    set POST_READ_TCL ""
}

if {[catch {
    flow_source_optional $PRE_READ_TCL "pre-read Tcl hook"
} msg]} {
    flow_fatal $msg
}

# ------------------------------------------------------------
# Read HDL
# ------------------------------------------------------------
if {[catch {
    flow_read_all_hdl
} msg]} {
    flow_fatal "HDL read failed: $msg"
}

# ------------------------------------------------------------
# Optional post-read hook
# ------------------------------------------------------------
if {[catch {
    flow_source_optional $POST_READ_TCL "post-read Tcl hook"
} msg]} {
    flow_fatal $msg
}

# ------------------------------------------------------------
# Elaborate
# ------------------------------------------------------------
puts "INFO: Elaborating top module: $TOP_MODULE"
elaborate $TOP_MODULE

uniquify $TOP_MODULE -verbose

catch {time_info Elaboration}

set num_ffs_elab 0
catch {set num_ffs_elab [llength [get_db insts -if {.is_flop == true}]]}
puts "INFO: Num FFs after elaboration: $num_ffs_elab"

check_design -unresolved
check_design -all > $REP_GEN/${DESIGN_NAME}.check_design.rpt

set SYNTH(BlackBox) 0
set SYNTH(Unresolved) 0

catch {set SYNTH(BlackBox) [llength [get_db design:$TOP_MODULE .blackboxes]]}
catch {set SYNTH(Unresolved) [llength [get_db hinsts -if {.unresolved==true}]]}

puts "INFO: BlackBox count   = $SYNTH(BlackBox)"
puts "INFO: Unresolved count = $SYNTH(Unresolved)"

if {$SYNTH(BlackBox) || $SYNTH(Unresolved)} {
    flow_fatal "Unresolved references or blackboxes found. Check $REP_GEN/${DESIGN_NAME}.check_design.rpt"
}

# ------------------------------------------------------------
# Constraints
# ------------------------------------------------------------
set_units -time ns
set_units -capacitance fF

if {![info exists SDC_FILE]} {
    set SDC_FILE "./constraints.sdc"
}

if {[file exists $SDC_FILE]} {
    puts "INFO: Reading SDC file: $SDC_FILE"
    read_sdc $SDC_FILE
} else {
    puts "WARNING: SDC file not found: $SDC_FILE"
    puts "WARNING: Creating basic clock."
    create_clock -name $CLOCK_PORT -period $CLOCK_PERIOD [get_ports $CLOCK_PORT]
}

if {[info exists ::dc::sdc_failed_commands]} {
    echo $::dc::sdc_failed_commands > $REPORT_DIR/sdc_failed_commands.rpt
}

set fp_excep [open "$REPORT_DIR/exceptions.rpt" "w"]
if {![catch {set all_exceptions [get_db exceptions]} msg]} {
    foreach excep $all_exceptions {
        set line "[get_db $excep .name] \t [get_db $excep .exception_type] \t [get_db $excep .priority]"
        puts $line
        puts $fp_excep $line
    }
} else {
    puts "WARNING: Could not query exceptions: $msg"
}
close $fp_excep

check_timing_intent -verbose > $REP_GEN/check_timing.rpt
if {$CHECK_ONLY} {
    puts "============================================================"
    puts "INFO: HDL check completed successfully"
    puts "INFO: DESIGN_NAME = $DESIGN_NAME"
    puts "INFO: TOP_MODULE  = $TOP_MODULE"
    puts "INFO: No unresolved modules or blackboxes were found"
    puts "INFO: Stopping before syn_generic"
    puts "============================================================"

    report_messages -all \
        > $REP_GEN/${DESIGN_NAME}.check.messages.rpt

    if {$EXIT_AFTER_RUN} {
        exit
    } else {
        return
    }
}
# ------------------------------------------------------------
# Cost groups
# ------------------------------------------------------------
catch {define_cost_group -name I2O -design $TOP_MODULE}
catch {define_cost_group -name I2C -design $TOP_MODULE}
catch {define_cost_group -name C2O -design $TOP_MODULE}
catch {define_cost_group -name C2C -design $TOP_MODULE}

catch {path_group -from [all_registers] -to [all_registers] -group C2C -name C2C}
catch {path_group -from [all_registers] -to [all_outputs]   -group C2O -name C2O}
catch {path_group -from [all_inputs]    -to [all_registers] -group I2C -name I2C}
catch {path_group -from [all_inputs]    -to [all_outputs]   -group I2O -name I2O}

# ------------------------------------------------------------
# GUI mode stops here
# ------------------------------------------------------------
if {!$RUN_SYNTH} {
    puts "============================================================"
    puts "INFO: RUN_SYNTH is false."
    puts "INFO: Library, RTL, elaboration, constraints, and cost groups are loaded."
    puts "INFO: Stopping before syn_generic / syn_map / syn_opt."
    puts ""
    puts "INFO: You can now run manually in Genus GUI Tcl console:"
    puts "INFO:   syn_generic"
    puts "INFO:   syn_map"
    puts "INFO:   syn_opt"
    puts ""
    puts "INFO: To write results manually after syn_opt:"
    puts "INFO: write_hdl > $OUTPUT_DIR/${DESIGN_NAME}_mapped.v"
    puts "INFO: write_sdc > $OUTPUT_DIR/${DESIGN_NAME}.sdc"
    puts ""
    puts "INFO: This script intentionally does not exit Genus."
    puts "============================================================"

    catch {report_summary -directory $REP_GUI}
    catch {report_timing -path_type full -max_path 20 > $REP_GUI/${DESIGN_NAME}.gui.initial_timing.rpt}
    catch {report_gates > $REP_GUI/${DESIGN_NAME}.gui.initial_gates.rpt}

    return
}

# ------------------------------------------------------------
# Generic synthesis
# ------------------------------------------------------------
safe_set_db / .syn_generic_effort $GEN_EFF

puts "INFO: Running syn_generic"
syn_generic

catch {time_info GENERIC}

report_dp > $REP_GEN/${DESIGN_NAME}.generic.datapath.rpt
write_snapshot -outdir $DB_DIR -tag generic
report_summary -directory $REP_GEN

# ------------------------------------------------------------
# Mapping
# ------------------------------------------------------------
safe_set_db / .syn_map_effort $MAP_OPT_EFF

puts "INFO: Running syn_map"
syn_map

catch {time_info MAPPED}

write_snapshot -outdir $DB_DIR -tag map
report_summary -directory $REP_MAP

set num_regs 0
set num_nets 0
catch {set num_regs [llength [get_db insts -if {.is_flop == true}]]}
catch {set num_nets [get_db designs .num_nets]}
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

write_snapshot -outdir $DB_DIR -tag opt
report_summary -directory $REP_OPT

catch {time_info OPT}

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

set num_regs 0
set num_nets 0
catch {set num_regs [llength [get_db insts -if {.is_flop == true}]]}
catch {set num_nets [get_db designs .num_nets]}
echo "Num FFs: $num_regs\nNum Nets: $num_nets" > ${REP_OPT}/stats.opt.rpt

# ------------------------------------------------------------
# Write backend file set
# ------------------------------------------------------------
write_hdl > $OUTPUT/${DESIGN_NAME}.mapped.v
write_sdc > $OUTPUT/${DESIGN_NAME}.mapped.sdc

file copy -force $OUTPUT/${DESIGN_NAME}.mapped.v $OUTPUT_DIR/${DESIGN_NAME}_mapped.v
file copy -force $OUTPUT/${DESIGN_NAME}.mapped.sdc $OUTPUT_DIR/${DESIGN_NAME}.sdc

# ------------------------------------------------------------
# Manifest
# ------------------------------------------------------------
set manifest_file "$OUTPUT/${DESIGN_NAME}.manifest.txt"
set fp [open $manifest_file "w"]

puts $fp "DESIGN_NAME: $DESIGN_NAME"
puts $fp "TOP_MODULE: $TOP_MODULE"
puts $fp "RTL_ROOT: $RTL_ROOT"
puts $fp "FILELIST: $FILELIST"
puts $fp "SDC_FILE: $SDC_FILE"
puts $fp "CLOCK_PORT: $CLOCK_PORT"
puts $fp "CLOCK_PERIOD: $CLOCK_PERIOD"
puts $fp "SYN_LIBS: $SYN_LIBS"
puts $fp "USE_PHYSICAL: $USE_PHYSICAL"
puts $fp "INSERT_CLOCK_GATING: $INSERT_CLOCK_GATING"
puts $fp "RUN_SYNTH: $RUN_SYNTH"
puts $fp "EXIT_AFTER_RUN: $EXIT_AFTER_RUN"
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
catch {time_info FINAL}
puts "============================================================"
puts "Synthesis Finished"
puts "DESIGN_NAME: $DESIGN_NAME"
puts "Mapped netlist: $OUTPUT/${DESIGN_NAME}.mapped.v"
puts "Manifest:       $manifest_file"
puts "============================================================"

if {$EXIT_AFTER_RUN} {
    exit
} else {
    return
}