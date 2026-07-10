# Run the full synthesis sequence from an already loaded GUI session.

syn_generic
syn_map
syn_opt

set output_dir "./outputs"
set report_dir "./reports/gui"

file mkdir $output_dir
file mkdir $report_dir

write_hdl > "$output_dir/${DESIGN_NAME}_mapped.v"
write_sdc > "$output_dir/${DESIGN_NAME}.sdc"

report_timing -path_type full -max_path 100 \
    > "$report_dir/${DESIGN_NAME}.gui.after_opt_timing.rpt"

report_gates \
    > "$report_dir/${DESIGN_NAME}.gui.after_opt_gates.rpt"

report_power \
    > "$report_dir/${DESIGN_NAME}.gui.after_opt_power.rpt"

puts "INFO: GUI synthesis results written for $DESIGN_NAME"