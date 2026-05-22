# create_project.tcl
# 为 FPGA 频谱分析仪课程设计创建 Vivado 仿真工程。

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file normalize [file join $script_dir ..]]
set proj_dir   [file join $proj_root vivado_project]
set proj_name  spectrum_analyzer

create_project -force $proj_name $proj_dir -part xc7a35tcpg236-1
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

set rtl_files [glob -nocomplain \
    [file join $proj_root rtl top *.v] \
    [file join $proj_root rtl common *.v] \
    [file join $proj_root rtl ctrl *.v] \
    [file join $proj_root rtl dds *.v] \
    [file join $proj_root rtl window *.v] \
    [file join $proj_root rtl fifo *.v] \
    [file join $proj_root rtl fft *.v] \
    [file join $proj_root rtl postproc *.v] \
    [file join $proj_root rtl vga *.v]]

set sim_model_files [glob -nocomplain [file join $proj_root rtl sim_model *.v]]
set tb_files [concat $sim_model_files [glob -nocomplain [file join $proj_root sim tb *.sv]]]

add_files -fileset sources_1 $rtl_files
add_files -fileset sim_1 $tb_files
set_property top spec_analyzer_top [get_filesets sources_1]
set_property top tb_spec_analyzer_top [get_filesets sim_1]
set_property verilog_define {XFFT_BEHAVIORAL_DFT_SIM} [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "已创建 Vivado 工程：$proj_dir"
puts "默认仿真顶层：tb_spec_analyzer_top"
