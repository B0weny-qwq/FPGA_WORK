# export_schematic.tcl
# 生成电路图查看辅助材料，并尽量导出层级报告。

set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file normalize [file join $script_dir ..]]
set report_dir [file join $proj_root reports]
file mkdir $report_dir

if {[catch {current_project}]} {
    source [file join $script_dir setup_full_project.tcl]
}

set guide_path [file join $report_dir schematic_guide.md]
set fp [open $guide_path w]
fconfigure $fp -encoding utf-8
puts $fp "# Schematic Review Guide"
puts $fp ""
puts $fp "1. Open `vivado_project/spectrum_analyzer.xpr` in Vivado."
puts $fp "2. Open elaborated design and expand from `spec_analyzer_top`."
puts $fp "3. After `scripts/run_synth_check.tcl`, open synthesized design to inspect the netlist hierarchy."
puts $fp "4. Follow this path: `dds_signal_gen -> win_mul_optional -> async_fifo_bridge/async_fifo -> fft_frame_ctrl -> xfft_wrapper/xfft_256 -> fft_mag_calc -> peak_detector/mag_compress -> spec_bin_buffer -> vga_timing_gen/spectrum_renderer/osd_text_gen/overlay_mux`."
puts $fp ""
puts $fp "Handwritten RTL: DDS, Hann window, default FIFO RTL, frame control, magnitude, peak, compression, VGA."
puts $fp "Real IP in synthesis path: `xfft_256`."
puts $fp "Optional/demo IP imported into project: `async_sample_fifo_ip`, `sine_rom_256`, `hann_rom_256`, `spec_bin_bram`."
close $fp

if {[catch {open_elaborated_design} err]} {
    puts "提示：当前环境未打开 elaborated design：$err"
} else {
    if {[catch {report_hierarchy -file [file join $report_dir elaborated_hierarchy.rpt] -force} rpt_err]} {
        puts "提示：elaborated 层级报告导出失败：$rpt_err"
    }
}

puts "电路图说明材料已生成：$guide_path"
