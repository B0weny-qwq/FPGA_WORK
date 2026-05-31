# setup_with_fft_ip.tcl
# 兼容旧入口：创建完整工程并生成所有计划 IP。

set script_dir [file dirname [file normalize [info script]]]
cd [file normalize [file join $script_dir ..]]

source scripts/setup_full_project.tcl

puts "完成：Vivado 工程、xfft_256 和展示型 IP 已准备好。"
puts "工程目录：vivado_project"
