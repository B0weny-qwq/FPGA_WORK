# fix_project_sources.tcl
# 功能: 修复旧 Vivado GUI 工程未导入新增 RTL/IP 时的综合报错。
# 典型现象: [Synth 8-439] module 'async_fifo_bridge' not found。

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file normalize [file join $script_dir ..]]
set proj_dir   [file join $proj_root vivado_project]
set proj_xpr   [file join $proj_dir spectrum_analyzer.xpr]
set ip_dir     [file join $proj_root ip]

if {[catch {current_project}]} {
    if {[file exists $proj_xpr]} {
        open_project $proj_xpr
    } else {
        puts "未找到已有工程，改为重新创建完整工程。"
        source [file join $script_dir setup_full_project.tcl]
        return
    }
}

proc add_files_if_missing {fileset_name file_list} {
    foreach src $file_list {
        if {![file exists $src]} {
            puts "警告: 文件不存在，跳过: $src"
            continue
        }

        if {[llength [get_files -quiet $src]] == 0} {
            add_files -fileset $fileset_name $src
            puts "已补加到 $fileset_name: $src"
        }
    }
}

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

set sim_files [concat \
    [glob -nocomplain [file join $proj_root rtl sim_model *.v]] \
    [glob -nocomplain [file join $proj_root sim tb *.sv]]]

set ip_xci_files [glob -nocomplain [file join $ip_dir * *.xci]]

add_files_if_missing sources_1 $rtl_files
add_files_if_missing sim_1 $sim_files
add_files_if_missing sources_1 $ip_xci_files

set_property top spec_analyzer_top [get_filesets sources_1]
set_property top tb_spec_analyzer_top [get_filesets sim_1]
set_property verilog_define {XFFT_BEHAVIORAL_DFT_SIM} [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

if {[llength [get_files -quiet [file join $proj_root rtl fifo async_fifo_bridge.v]]] == 0} {
    error "async_fifo_bridge.v 仍未加入工程，请检查工程路径是否为 $proj_root"
}

if {[catch {save_project} save_err]} {
    puts "提示: 当前 Vivado 版本未执行无参数 save_project；source 引用已在当前工程会话刷新。"
    puts "提示: 如需持久化 GUI 工程文件，请在 Vivado 中执行 File -> Save Project。"
}

puts "工程 source 引用已刷新，可重新运行 Synthesis。"
