# run_all_sims.tcl
# 批量运行四个课程验收 testbench。请先 source scripts/setup_full_project.tcl。

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file normalize [file join $script_dir ..]]
set report_dir [file join $proj_root reports]
file mkdir $report_dir

if {[catch {current_project}]} {
    source [file join $script_dir setup_full_project.tcl]
}

set tb_list {tb_async_fifo tb_fft_chain tb_vga_render tb_spec_analyzer_top}
set_property verilog_define {XFFT_BEHAVIORAL_DFT_SIM} [get_filesets sim_1]

set log_path [file join $report_dir sim_summary.md]
set fp [open $log_path w]
fconfigure $fp -encoding utf-8
puts $fp "# Simulation Summary"
puts $fp ""
puts $fp "| Testbench | Status |"
puts $fp "| --- | --- |"

foreach tb $tb_list {
    puts "开始仿真：$tb"
    catch {close_sim -force}

    set_property top $tb [get_filesets sim_1]
    update_compile_order -fileset sim_1

    if {[catch {
        launch_simulation -simset sim_1 -mode behavioral
        run -all
    } err]} {
        puts $fp "| `$tb` | FAILED: $err |"
        close $fp
        error "仿真失败：$tb，$err"
    } else {
        puts $fp "| `$tb` | PASS |"
    }
}

if {![catch {current_sim}]} {
    close_sim -force
}

close $fp
puts "四个 testbench 已运行完成，汇总报告：$log_path"
