# create_project.tcl
# 兼容旧入口：创建完整 Vivado 工程。推荐直接使用 setup_full_project.tcl。

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir setup_full_project.tcl]
