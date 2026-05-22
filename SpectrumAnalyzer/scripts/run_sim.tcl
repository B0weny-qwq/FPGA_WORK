# run_sim.tcl
# 启动指定的 Vivado 仿真顶层。

if {![info exists sim_top]} {
    set sim_top tb_spec_analyzer_top
}

set_property top $sim_top [get_filesets sim_1]
set_property verilog_define {XFFT_BEHAVIORAL_DFT_SIM} [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation

if {![info exists sim_time]} {
    set sim_time 10ms
}

run $sim_time
puts "仿真 $sim_top 已运行 $sim_time"
