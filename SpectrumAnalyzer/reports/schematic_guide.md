# Schematic Review Guide

1. Open `vivado_project/spectrum_analyzer.xpr` in Vivado.
2. Open elaborated design and expand from `spec_analyzer_top`.
3. After `scripts/run_synth_check.tcl`, open synthesized design to inspect the netlist hierarchy.
4. Follow this path: `dds_signal_gen -> win_mul_optional -> async_fifo_bridge/async_fifo -> fft_frame_ctrl -> xfft_wrapper/xfft_256 -> fft_mag_calc -> peak_detector/mag_compress -> spec_bin_buffer -> vga_timing_gen/spectrum_renderer/osd_text_gen/overlay_mux`.

Handwritten RTL: DDS, Hann window, default FIFO RTL, frame control, magnitude, peak, compression, VGA.
Real IP in synthesis path: `xfft_256`.
Optional/demo IP imported into project: `async_sample_fifo_ip`, `sine_rom_256`, `hann_rom_256`, `spec_bin_bram`.
