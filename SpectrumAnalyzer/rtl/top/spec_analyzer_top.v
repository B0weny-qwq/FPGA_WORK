// 模块名: spec_analyzer_top
// 功能: 仿真频谱分析仪顶层集成
// 时钟域: clk_sample, clk_fft, clk_pixel
// 输入: 三路时钟、复位和仿真控制信号
// 输出: VGA 风格 RGB/同步信号和调试状态
// 说明: 固定路线为 DDS -> 窗口 -> FIFO -> FFT -> 幅度 -> VGA 渲染

`timescale 1ns / 1ps

module spec_analyzer_top #(
    parameter DATA_WIDTH   = 16,
    parameter PHASE_WIDTH  = 32,
    parameter FFT_SIZE     = 256,
    parameter DISPLAY_BINS = 128
) (
    input  wire        clk_sample,
    input  wire        clk_fft,
    input  wire        clk_pixel,
    input  wire        rst_n,
    input  wire [1:0]  wave_sel,
    input  wire [31:0] freq_word,
    input  wire        dual_tone_en,
    input  wire        window_en,
    output wire        vga_hs,
    output wire        vga_vs,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    output wire [7:0]  debug_peak_bin,
    output wire [31:0] debug_peak_mag,
    output wire        debug_peak_valid,
    output wire        debug_fifo_full,
    output wire        debug_fifo_empty,
    output wire [7:0]  debug_fft_bin
);

    localparam FIFO_ADDR_WIDTH = 9;
    localparam BIN_WIDTH       = 8;
    localparam LEVEL_WIDTH     = 8;
    localparam READ_ADDR_W     = 7;

    wire sample_rst_n;
    wire fft_rst_n;
    wire pixel_rst_n;

    wire signed [DATA_WIDTH-1:0] dds_sample;
    wire                         dds_valid;
    wire [PHASE_WIDTH-1:0]       dds_phase;

    wire signed [DATA_WIDTH-1:0] window_sample;
    wire                         window_valid;
    wire [7:0]                   window_addr;

    wire                         fifo_wr_en;
    wire                         fifo_rd_en;
    wire signed [DATA_WIDTH-1:0] fifo_rd_data;
    wire                         fifo_rd_valid;
    wire                         fifo_full;
    wire                         fifo_empty;
    wire [FIFO_ADDR_WIDTH:0]     fifo_wr_level;
    wire [FIFO_ADDR_WIDTH:0]     fifo_rd_level;

    wire [2*DATA_WIDTH-1:0] fft_in_tdata;
    wire                    fft_in_tvalid;
    wire                    fft_in_tlast;
    wire                    fft_in_tready;
    wire                    frame_start;
    wire                    frame_done;
    wire [7:0]              frame_sample_cnt;

    wire [2*DATA_WIDTH-1:0] fft_out_tdata;
    wire                    fft_out_tvalid;
    wire                    fft_out_tlast;
    wire                    fft_event_tlast_missing;
    wire                    fft_event_tlast_unexpected;

    wire [31:0] mag_data;
    wire [7:0]  mag_bin;
    wire        mag_valid;
    wire        mag_frame_done;

    wire [7:0] level_data;
    wire [7:0] level_bin;
    wire       level_valid;
    wire       level_frame_done;

    wire [6:0] bin_rd_addr;
    wire [7:0] bin_rd_level;
    wire       spectrum_frame_toggle;

    wire        active_video;
    wire [9:0]  pixel_x;
    wire [9:0]  pixel_y;
    wire        vga_frame_tick;
    wire [11:0] spectrum_rgb;
    wire        spectrum_on;
    wire [11:0] osd_rgb;
    wire        osd_on;
    wire [7:0]  debug_peak_bin_int;
    wire [31:0] debug_peak_mag_int;
    wire        debug_peak_valid_int;

    assign fifo_wr_en = window_valid & ~fifo_full;
    assign debug_peak_bin = debug_peak_bin_int;
    assign debug_peak_mag = debug_peak_mag_int;
    assign debug_peak_valid = debug_peak_valid_int;
    assign debug_fifo_full = fifo_full;
    assign debug_fifo_empty = fifo_empty;

    clk_rst_gen u_clk_rst_gen (
        .clk_sample   (clk_sample),
        .clk_fft      (clk_fft),
        .clk_pixel    (clk_pixel),
        .rst_n        (rst_n),
        .sample_rst_n (sample_rst_n),
        .fft_rst_n    (fft_rst_n),
        .pixel_rst_n  (pixel_rst_n)
    );

    dds_signal_gen #(
        .PHASE_WIDTH (PHASE_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_dds_signal_gen (
        .clk_sample       (clk_sample),
        .sample_rst_n     (sample_rst_n),
        .wave_sel         (wave_sel),
        .freq_word        (freq_word),
        .dual_tone_en     (dual_tone_en),
        .sample_data      (dds_sample),
        .sample_valid     (dds_valid),
        .debug_phase_word (dds_phase)
    );

    win_mul_optional #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ADDR_WIDTH  (8),
        .COEFF_WIDTH (16)
    ) u_win_mul_optional (
        .clk_sample       (clk_sample),
        .sample_rst_n     (sample_rst_n),
        .window_en        (window_en),
        .sample_in        (dds_sample),
        .sample_in_valid  (dds_valid),
        .sample_out       (window_sample),
        .sample_out_valid (window_valid),
        .debug_coeff_addr (window_addr)
    );

    async_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (FIFO_ADDR_WIDTH)
    ) u_async_fifo (
        .clk_wr         (clk_sample),
        .wr_rst_n       (sample_rst_n),
        .clk_rd         (clk_fft),
        .rd_rst_n       (fft_rst_n),
        .wr_en          (fifo_wr_en),
        .wr_data        (window_sample),
        .rd_en          (fifo_rd_en),
        .rd_data        (fifo_rd_data),
        .rd_valid       (fifo_rd_valid),
        .full           (fifo_full),
        .empty          (fifo_empty),
        .debug_wr_level (fifo_wr_level),
        .debug_rd_level (fifo_rd_level)
    );

    fft_frame_ctrl #(
        .DATA_WIDTH (DATA_WIDTH),
        .FFT_SIZE   (FFT_SIZE),
        .CNT_WIDTH  (BIN_WIDTH)
    ) u_fft_frame_ctrl (
        .clk_fft            (clk_fft),
        .fft_rst_n          (fft_rst_n),
        .fifo_empty         (fifo_empty),
        .fifo_rd_data       (fifo_rd_data),
        .fifo_rd_valid      (fifo_rd_valid),
        .fft_in_ready       (fft_in_tready),
        .fifo_rd_en         (fifo_rd_en),
        .fft_s_axis_tdata   (fft_in_tdata),
        .fft_s_axis_tvalid  (fft_in_tvalid),
        .fft_s_axis_tlast   (fft_in_tlast),
        .frame_start        (frame_start),
        .frame_done         (frame_done),
        .debug_sample_cnt   (frame_sample_cnt)
    );

    xfft_wrapper #(
        .DATA_WIDTH (DATA_WIDTH),
        .FFT_SIZE   (FFT_SIZE),
        .BIN_WIDTH  (BIN_WIDTH)
    ) u_xfft_wrapper (
        .clk_fft                  (clk_fft),
        .fft_rst_n                (fft_rst_n),
        .s_axis_tdata             (fft_in_tdata),
        .s_axis_tvalid            (fft_in_tvalid),
        .s_axis_tlast             (fft_in_tlast),
        .s_axis_tready            (fft_in_tready),
        .m_axis_tdata             (fft_out_tdata),
        .m_axis_tvalid            (fft_out_tvalid),
        .m_axis_tlast             (fft_out_tlast),
        .m_axis_tready            (1'b1),
        .event_tlast_missing      (fft_event_tlast_missing),
        .event_tlast_unexpected   (fft_event_tlast_unexpected),
        .debug_out_bin            (debug_fft_bin)
    );

    fft_mag_calc #(
        .DATA_WIDTH (DATA_WIDTH),
        .MAG_WIDTH  (32),
        .BIN_WIDTH  (BIN_WIDTH),
        .FFT_SIZE   (FFT_SIZE)
    ) u_fft_mag_calc (
        .clk_fft        (clk_fft),
        .fft_rst_n      (fft_rst_n),
        .fft_tdata      (fft_out_tdata),
        .fft_tvalid     (fft_out_tvalid),
        .fft_tlast      (fft_out_tlast),
        .mag_data       (mag_data),
        .mag_bin        (mag_bin),
        .mag_valid      (mag_valid),
        .mag_frame_done (mag_frame_done)
    );

    mag_compress #(
        .MAG_WIDTH   (32),
        .LEVEL_WIDTH (LEVEL_WIDTH),
        .BIN_WIDTH   (BIN_WIDTH),
        .MAX_LEVEL   (220)
    ) u_mag_compress (
        .clk_fft          (clk_fft),
        .fft_rst_n        (fft_rst_n),
        .mag_data         (mag_data),
        .mag_bin          (mag_bin),
        .mag_valid        (mag_valid),
        .mag_frame_done   (mag_frame_done),
        .level_data       (level_data),
        .level_bin        (level_bin),
        .level_valid      (level_valid),
        .level_frame_done (level_frame_done)
    );

    peak_detector #(
        .MAG_WIDTH (32),
        .BIN_WIDTH (BIN_WIDTH)
    ) u_peak_detector (
        .clk_fft        (clk_fft),
        .fft_rst_n      (fft_rst_n),
        .mag_data       (mag_data),
        .mag_bin        (mag_bin),
        .mag_valid      (mag_valid),
        .mag_frame_done (mag_frame_done),
        .peak_bin       (debug_peak_bin_int),
        .peak_mag       (debug_peak_mag_int),
        .peak_valid     (debug_peak_valid_int)
    );

    spec_bin_buffer #(
        .BIN_WIDTH    (BIN_WIDTH),
        .LEVEL_WIDTH  (LEVEL_WIDTH),
        .DISPLAY_BINS (DISPLAY_BINS),
        .READ_ADDR_W  (READ_ADDR_W)
    ) u_spec_bin_buffer (
        .clk_fft          (clk_fft),
        .fft_rst_n        (fft_rst_n),
        .level_bin        (level_bin),
        .level_data       (level_data),
        .level_valid      (level_valid),
        .level_frame_done (level_frame_done),
        .clk_pixel        (clk_pixel),
        .pixel_rst_n      (pixel_rst_n),
        .rd_bin           (bin_rd_addr),
        .rd_level         (bin_rd_level),
        .frame_toggle     (spectrum_frame_toggle)
    );

    vga_timing_gen u_vga_timing_gen (
        .clk_pixel    (clk_pixel),
        .pixel_rst_n  (pixel_rst_n),
        .vga_hs       (vga_hs),
        .vga_vs       (vga_vs),
        .active_video (active_video),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .frame_tick   (vga_frame_tick)
    );

    spectrum_renderer #(
        .H_ACTIVE     (640),
        .V_ACTIVE     (480),
        .DISPLAY_BINS (DISPLAY_BINS),
        .READ_ADDR_W  (READ_ADDR_W),
        .LEVEL_WIDTH  (LEVEL_WIDTH),
        .BAR_MAX_H    (220)
    ) u_spectrum_renderer (
        .clk_pixel    (clk_pixel),
        .pixel_rst_n  (pixel_rst_n),
        .active_video (active_video),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .bin_level    (bin_rd_level),
        .bin_rd_addr  (bin_rd_addr),
        .spectrum_rgb (spectrum_rgb),
        .spectrum_on  (spectrum_on)
    );

    osd_text_gen u_osd_text_gen (
        .clk_pixel    (clk_pixel),
        .pixel_rst_n  (pixel_rst_n),
        .active_video (active_video),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .wave_sel     (wave_sel),
        .window_en    (window_en),
        .peak_bin     (debug_peak_bin_int),
        .osd_rgb      (osd_rgb),
        .osd_on       (osd_on)
    );

    overlay_mux u_overlay_mux (
        .clk_pixel    (clk_pixel),
        .pixel_rst_n  (pixel_rst_n),
        .active_video (active_video),
        .spectrum_rgb (spectrum_rgb),
        .spectrum_on  (spectrum_on),
        .osd_rgb      (osd_rgb),
        .osd_on       (osd_on),
        .vga_r        (vga_r),
        .vga_g        (vga_g),
        .vga_b        (vga_b)
    );

endmodule
