# ============================================================
# Common helper procedures for Cadence Genus synthesis
# ============================================================

proc flow_warn {msg} {
    puts "WARNING: $msg"
}

proc flow_require_var {var_name} {
    upvar 1 $var_name value

    if {![info exists value] || [string trim $value] eq ""} {
        error "Required configuration variable is missing: $var_name"
    }
}

proc flow_require_file {path description} {
    if {![file isfile $path]} {
        error "$description does not exist: $path"
    }
}

proc flow_require_dir {path description} {
    if {![file isdirectory $path]} {
        error "$description does not exist: $path"
    }
}

proc flow_normalize_list {items} {
    set normalized {}

    foreach item $items {
        if {[string trim $item] eq ""} {
            continue
        }

        lappend normalized [file normalize $item]
    }

    return $normalized
}

proc flow_validate_files {files description} {
    foreach path $files {
        flow_require_file $path $description
    }
}

proc flow_validate_dirs {dirs description} {
    foreach path $dirs {
        flow_require_dir $path $description
    }
}

proc flow_source_optional {script_path description} {
    if {[string trim $script_path] eq ""} {
        return
    }

    set script_path [file normalize $script_path]
    flow_require_file $script_path $description

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

    # Backward compatibility with the original single FILELIST.
    if {[llength $HDL_FILELISTS] == 0 &&
        [llength $HDL_PACKAGE_FILES] == 0 &&
        [llength $HDL_RTL_FILES] == 0} {

        if {[info exists FILELIST] && [string trim $FILELIST] ne ""} {
            set HDL_FILELISTS [list $FILELIST]
        }
    }

    set HDL_FILELISTS      [flow_normalize_list $HDL_FILELISTS]
    set HDL_PACKAGE_FILES  [flow_normalize_list $HDL_PACKAGE_FILES]
    set HDL_RTL_FILES      [flow_normalize_list $HDL_RTL_FILES]
    set HDL_INCLUDE_DIRS   [flow_normalize_list $HDL_INCLUDE_DIRS]

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

proc flow_apply_hdl_environment {} {
    global HDL_INCLUDE_DIRS
    global HDL_DEFINES

    if {[llength $HDL_INCLUDE_DIRS] > 0} {
        puts "INFO: HDL include directories:"
        foreach directory $HDL_INCLUDE_DIRS {
            puts "INFO:   $directory"
        }

        # Genus HDL search path used for `include resolution.
        set_db hdl_search_path $HDL_INCLUDE_DIRS
    }

    if {[llength $HDL_DEFINES] > 0} {
        puts "INFO: HDL defines:"
        foreach define $HDL_DEFINES {
            puts "INFO:   $define"
        }
    }
}

proc flow_read_sv_files {files description} {
    global HDL_DEFINES

    if {[llength $files] == 0} {
        return
    }

    puts "INFO: Reading $description"

    if {[llength $HDL_DEFINES] > 0} {
        read_hdl -sv -define $HDL_DEFINES $files
    } else {
        read_hdl -sv $files
    }
}

proc flow_read_sv_filelists {filelists} {
    global HDL_DEFINES

    foreach filelist $filelists {
        puts "INFO: Reading HDL filelist: $filelist"

        if {[llength $HDL_DEFINES] > 0} {
            read_hdl -sv -define $HDL_DEFINES -f $filelist
        } else {
            read_hdl -sv -f $filelist
        }
    }
}

proc flow_read_all_hdl {} {
    global HDL_PACKAGE_FILES
    global HDL_FILELISTS
    global HDL_RTL_FILES

    flow_collect_hdl_configuration
    flow_apply_hdl_environment

    # Explicit package files must be analyzed first.
    flow_read_sv_files $HDL_PACKAGE_FILES \
        "ordered SystemVerilog package files"

    # Multiple filelists are processed in the declared order.
    flow_read_sv_filelists $HDL_FILELISTS

    # Explicit RTL sources are analyzed last.
    flow_read_sv_files $HDL_RTL_FILES \
        "ordered SystemVerilog RTL files"
}