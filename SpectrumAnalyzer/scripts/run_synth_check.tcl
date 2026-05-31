# run_synth_check.tcl
# 综合 spec_analyzer_top，并导出利用率、时序和层级结构报告。

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file normalize [file join $script_dir ..]]
set report_dir [file join $proj_root reports]
set part_name  xc7a35tcpg236-1
file mkdir $report_dir

if {[catch {current_project}]} {
    source [file join $script_dir setup_full_project.tcl]
}

update_compile_order -fileset sources_1

set_property top spec_analyzer_top [get_filesets sources_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]

reset_run synth_1
launch_runs synth_1 -jobs 2
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
if {[string first "Complete" $synth_status] < 0} {
    error "综合失败：synth_1 状态为 $synth_status"
}

open_run synth_1 -name synth_1

report_utilization -file [file join $report_dir synth_utilization.rpt] -force
file delete -force [file join $report_dir timing_summary.rpt]
report_timing_summary -file [file join $report_dir timing_summary.rpt]
file delete -force [file join $report_dir compile_order.rpt]
report_compile_order -fileset sources_1 -file [file join $report_dir compile_order.rpt]

if {[catch {report_hierarchy -file [file join $report_dir hierarchy.rpt] -force} err]} {
    set fp [open [file join $report_dir hierarchy.rpt] w]
    fconfigure $fp -encoding utf-8
    puts $fp "report_hierarchy is unavailable; fallback to get_cells hierarchy list."
    puts $fp $err
    foreach cell [lsort [get_cells -hierarchical *]] {
        puts $fp $cell
    }
    close $fp
}

write_checkpoint -force [file join $report_dir spec_analyzer_top_synth.dcp]

set fp [open [file join $report_dir synth_summary.md] w]
fconfigure $fp -encoding utf-8
puts $fp "# Synthesis Check Summary"
puts $fp ""
puts $fp "- Top: `spec_analyzer_top`"
puts $fp "- Strategy: `flatten_hierarchy none`, keeping the main hierarchy readable for schematic review."
puts $fp "- FFT: `xfft_wrapper` instantiates real `xfft_256` IP when `XFFT_BEHAVIORAL_DFT_SIM` is not defined."
puts $fp "- Reports: `synth_utilization.rpt`, `timing_summary.rpt`, `hierarchy.rpt`, `compile_order.rpt`."
close $fp

puts "综合检查完成，报告目录：$report_dir"
