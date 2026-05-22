# gen_ip_fft.tcl
# 生成固定参数的 256 点 Vivado FFT IP，用于替换 xfft_wrapper 行为模型。

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file normalize [file join $script_dir ..]]

if {[catch {current_project}]} {
    create_project -force spectrum_analyzer_ip [file join $proj_root ip vivado_ip_project] \
        -part xc7a35tcpg236-1
}

create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 \
    -module_name xfft_256 -dir [file join $proj_root ip]

set_property -dict [list \
    CONFIG.transform_length {256} \
    CONFIG.implementation_options {pipelined_streaming_io} \
    CONFIG.input_width {16} \
    CONFIG.phase_factor_width {16} \
    CONFIG.scaling_options {scaled} \
    CONFIG.rounding_modes {truncation} \
    CONFIG.aresetn {true}] [get_ips xfft_256]

generate_target all [get_ips xfft_256]
export_ip_user_files -of_objects [get_ips xfft_256] -no_script -sync -force -quiet

puts "已在 ip/xfft_256 下生成 xfft_256 IP。"
puts "建议只把 rtl/fft/xfft_wrapper.v 作为 FFT IP 集成修改点。"
