# gen_ip_all.tcl
# 生成或导入满分验收要求的 Vivado IP，并输出 IP 状态报告。

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file normalize [file join $script_dir ..]]
set ip_dir     [file join $proj_root ip]
set report_dir [file join $proj_root reports]
file mkdir $ip_dir
file mkdir $report_dir

if {![info exists part_name]} {
    set part_name xc7a35tcpg236-1
}

if {[catch {current_project}]} {
    create_project -force spectrum_analyzer_ip [file join $ip_dir vivado_ip_project] -part $part_name
}

proc find_ip_xci {root module_name} {
    set direct [file join $root $module_name ${module_name}.xci]
    if {[file exists $direct]} {
        return $direct
    }

    set candidates [glob -nocomplain [file join $root * ${module_name}.xci]]
    if {[llength $candidates] > 0} {
        return [lindex $candidates 0]
    }

    return $direct
}

proc create_or_read_ip {ip_root module_name ip_name vendor library version} {
    set ip_xci [find_ip_xci $ip_root $module_name]
    if {[file exists $ip_xci]} {
        read_ip $ip_xci
        puts "已读取 IP：$module_name -> $ip_xci"
    } else {
        create_ip -name $ip_name -vendor $vendor -library $library -version $version \
            -module_name $module_name -dir $ip_root
        set ip_xci [find_ip_xci $ip_root $module_name]
        puts "已创建 IP：$module_name"
    }

    return $ip_xci
}

proc set_ip_props_safe {module_name props} {
    set ip_obj [get_ips -quiet $module_name]
    if {[llength $ip_obj] == 0} {
        puts "警告：未找到 IP 对象 $module_name，跳过参数设置。"
        return
    }

    foreach {key value} $props {
        if {[catch {set_property $key $value $ip_obj} err]} {
            puts "警告：$module_name 参数 $key=$value 设置失败：$err"
        }
    }
}

proc generate_ip_safe {module_name} {
    set ip_obj [get_ips -quiet $module_name]
    if {[llength $ip_obj] == 0} {
        puts "警告：未找到 IP 对象 $module_name，跳过生成。"
        return
    }

    generate_target all $ip_obj
    export_ip_user_files -of_objects $ip_obj -no_script -sync -force -quiet
}

proc path_for_report {root path} {
    set root_norm [string trimright [file normalize $root] "/\\"]
    set path_norm [file normalize $path]
    set prefix "${root_norm}/"

    if {[string first $prefix $path_norm] == 0} {
        return [string range $path_norm [string length $prefix] end]
    }

    return $path_norm
}

set ip_status {}

set xfft_xci [create_or_read_ip $ip_dir xfft_256 xfft xilinx.com ip 9.1]
set_ip_props_safe xfft_256 [list \
    CONFIG.transform_length {256} \
    CONFIG.implementation_options {pipelined_streaming_io} \
    CONFIG.input_width {16} \
    CONFIG.phase_factor_width {16} \
    CONFIG.scaling_options {scaled} \
    CONFIG.rounding_modes {truncation} \
    CONFIG.aresetn {true}]
generate_ip_safe xfft_256
lappend ip_status [list xfft_256 $xfft_xci "synthesis path used by xfft_wrapper"]

set fifo_xci [create_or_read_ip $ip_dir async_sample_fifo_ip fifo_generator xilinx.com ip 13.2]
set_ip_props_safe async_sample_fifo_ip [list \
    CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
    CONFIG.Input_Data_Width {16} \
    CONFIG.Output_Data_Width {16} \
    CONFIG.Input_Depth {512} \
    CONFIG.Output_Depth {512} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Use_Embedded_Registers {false} \
    CONFIG.Valid_Flag {true}]
generate_ip_safe async_sample_fifo_ip
lappend ip_status [list async_sample_fifo_ip $fifo_xci "imported; optional path with USE_ASYNC_SAMPLE_FIFO_IP"]

set sine_xci [create_or_read_ip $ip_dir sine_rom_256 blk_mem_gen xilinx.com ip 8.4]
set_ip_props_safe sine_rom_256 [list \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Write_Depth_A {256} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Operating_Mode_A {READ_FIRST}]
generate_ip_safe sine_rom_256
lappend ip_status [list sine_rom_256 $sine_xci "DDS sine lookup ROM demonstration IP"]

set hann_xci [create_or_read_ip $ip_dir hann_rom_256 blk_mem_gen xilinx.com ip 8.4]
set_ip_props_safe hann_rom_256 [list \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Write_Width_A {16} \
    CONFIG.Write_Depth_A {256} \
    CONFIG.Read_Width_A {16} \
    CONFIG.Operating_Mode_A {READ_FIRST}]
generate_ip_safe hann_rom_256
lappend ip_status [list hann_rom_256 $hann_xci "Hann coefficient ROM demonstration IP"]

set bram_xci [create_or_read_ip $ip_dir spec_bin_bram blk_mem_gen xilinx.com ip 8.4]
set_ip_props_safe spec_bin_bram [list \
    CONFIG.Memory_Type {Simple_Dual_Port_RAM} \
    CONFIG.Write_Width_A {8} \
    CONFIG.Write_Depth_A {128} \
    CONFIG.Read_Width_A {8} \
    CONFIG.Write_Width_B {8} \
    CONFIG.Read_Width_B {8} \
    CONFIG.Operating_Mode_A {READ_FIRST} \
    CONFIG.Operating_Mode_B {READ_FIRST}]
generate_ip_safe spec_bin_bram
lappend ip_status [list spec_bin_bram $bram_xci "spectrum buffer BRAM demonstration IP"]

set status_path [file join $report_dir ip_status.md]
set fp [open $status_path w]
fconfigure $fp -encoding utf-8
puts $fp "# IP Status Report"
puts $fp ""
puts $fp "Generated by: `scripts/gen_ip_all.tcl`"
puts $fp ""
puts $fp "| IP | XCI Path | Purpose |"
puts $fp "| --- | --- | --- |"
foreach item $ip_status {
    lassign $item name xci purpose
    set rel_xci [file nativename [path_for_report $proj_root $xci]]
    puts $fp "| `$name` | `$rel_xci` | $purpose |"
}
close $fp

set all_xci [glob -nocomplain [file join $ip_dir * *.xci]]
if {[llength $all_xci] > 0} {
    foreach xci $all_xci {
        if {[llength [get_files -quiet $xci]] == 0} {
            add_files -fileset sources_1 $xci
        }
    }
    update_compile_order -fileset sources_1
}

puts "IP 生成/导入完成，状态报告：$status_path"
