# ============================================================
# Common helper procedures for Cadence Genus synthesis
#
# This file provides:
#   - ordered SystemVerilog package/source handling
#   - multiple ordered filelists
#   - include/search directories
#   - global HDL macro definitions
#   - optional pre-read and post-read Tcl hooks
#   - input validation
#
# It is sourced before genus_synth_common.tcl.  The procedures
# are executed later, after the common flow has defined its
# normal error-handling procedures.
# ============================================================

proc flow_normalize_path_list {items} {
    set normalized {}

    foreach item $items {
        set item [string trim $item]
        if {$item eq ""} {
            continue
        }
        lappend normalized [file normalize $item]
    }

    return $normalized
}

proc flow_validate_files {paths description} {
    foreach path $paths {
        if {![file isfile $path]} {
            error "$description does not exist: $path"
        }
    }
}

proc flow_validate_dirs {paths description} {
    foreach path $paths {
        if {![file isdirectory $path]} {
            error "$description does not exist: $path"
        }
    }
}

proc flow_source_optional {script_path description} {
    set script_path [string trim $script_path]

    if {$script_path eq ""} {
        return
    }

    set script_path [file normalize $script_path]
    if {![file isfile $script_path]} {
        error "$description does not exist: $script_path"
    }

    puts "INFO: Sourcing $description: $script_path"
    source $script_path
}

proc flow_collect_hdl_configuration {} {
    global FILELIST
    global HDL_FILELISTS
    global HDL_PACKAGE_FILES
    global HDL_RTL_FILES
    global HDL_INCLUDE_DIRS
    global HDL_DEFINES

    if {![info exists HDL_FILELISTS]} {
        set HDL_FILELISTS {}
    }
    if {![info exists HDL_PACKAGE_FILES]} {
        set HDL_PACKAGE_FILES {}
    }
    if {![info exists HDL_RTL_FILES]} {
        set HDL_RTL_FILES {}
    }
    if {![info exists HDL_INCLUDE_DIRS]} {
        set HDL_INCLUDE_DIRS {}
    }
    if {![info exists HDL_DEFINES]} {
        set HDL_DEFINES {}
    }

    # Backward compatibility with the original single FILELIST
    # interface.  It is used only when none of the new explicit
    # HDL input interfaces has been configured.
    if {[llength $HDL_FILELISTS] == 0 &&
        [llength $HDL_PACKAGE_FILES] == 0 &&
        [llength $HDL_RTL_FILES] == 0} {

        if {[info exists FILELIST] && [string trim $FILELIST] ne ""} {
            set HDL_FILELISTS [list $FILELIST]
        }
    }

    set HDL_FILELISTS     [flow_normalize_path_list $HDL_FILELISTS]
    set HDL_PACKAGE_FILES [flow_normalize_path_list $HDL_PACKAGE_FILES]
    set HDL_RTL_FILES     [flow_normalize_path_list $HDL_RTL_FILES]
    set HDL_INCLUDE_DIRS  [flow_normalize_path_list $HDL_INCLUDE_DIRS]

    flow_validate_files $HDL_FILELISTS "HDL filelist"
    flow_validate_files $HDL_PACKAGE_FILES "SystemVerilog package file"
    flow_validate_files $HDL_RTL_FILES "RTL source file"
    flow_validate_dirs $HDL_INCLUDE_DIRS "HDL include directory"

    if {[llength $HDL_FILELISTS] == 0 &&
        [llength $HDL_PACKAGE_FILES] == 0 &&
        [llength $HDL_RTL_FILES] == 0} {
        error "No HDL sources were configured"
    }
}

proc flow_configure_hdl_search_path {} {
    global HDL_INCLUDE_DIRS

    # Keep the current directory in the search path so that
    # existing relative-path projects remain compatible.
    set search_paths [list .]

    foreach directory $HDL_INCLUDE_DIRS {
        if {[lsearch -exact $search_paths $directory] < 0} {
            lappend search_paths $directory
        }
    }

    puts "INFO: HDL search/include directories:"
    foreach directory $search_paths {
        puts "INFO:   $directory"
    }

    if {[catch {set_db hdl_search_path $search_paths} msg]} {
        error "Unable to set hdl_search_path: $msg"
    }
}

proc flow_make_read_hdl_command {} {
    global HDL_DEFINES

    set command [list read_hdl -sv]

    # Cadence read_hdl accepts the macro definitions as one
    # Tcl list, for example: {SYNTHESIS RV32 FEATURE=1}.
    if {[llength $HDL_DEFINES] > 0} {
        lappend command -define $HDL_DEFINES
    }

    return $command
}

proc flow_read_sv_files {files description} {
    if {[llength $files] == 0} {
        return
    }

    puts "INFO: Reading $description"
    foreach file $files {
        puts "INFO:   $file"
    }

    # Read the entire ordered list in one read_hdl invocation.
    # This preserves ordering and a shared preprocessor scope
    # within this source group.
    set command [flow_make_read_hdl_command]
    foreach file $files {
        lappend command $file
    }

    uplevel #0 $command
}

proc flow_read_sv_filelists {filelists} {
    foreach filelist $filelists {
        puts "INFO: Reading HDL filelist: $filelist"

        # Each filelist is processed in the order declared by
        # HDL_FILELISTS.  Global HDL_DEFINES are applied to every
        # read_hdl invocation.
        set command [flow_make_read_hdl_command]
        lappend command -f $filelist
        uplevel #0 $command
    }
}

proc flow_read_all_hdl {} {
    global HDL_PACKAGE_FILES
    global HDL_FILELISTS
    global HDL_RTL_FILES
    global HDL_DEFINES

    flow_configure_hdl_search_path

    puts "INFO: HDL macro definitions:"
    if {[llength $HDL_DEFINES] == 0} {
        puts "INFO:   <none>"
    } else {
        foreach define $HDL_DEFINES {
            puts "INFO:   $define"
        }
    }

    # Explicit package files are read first.  Multiple filelists
    # are then read in their declared order.  Explicit RTL files
    # are read last.
    flow_read_sv_files $HDL_PACKAGE_FILES \
        "ordered SystemVerilog package files"
    flow_read_sv_filelists $HDL_FILELISTS
    flow_read_sv_files $HDL_RTL_FILES \
        "ordered SystemVerilog RTL files"
}
