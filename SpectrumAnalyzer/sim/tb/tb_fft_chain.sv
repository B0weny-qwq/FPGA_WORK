// 模块名: tb_fft_chain
// 功能: DDS 到 FFT 后处理链路仿真测试
// 时钟域: clk_sample 和 clk_fft
// 输入: 无外部输入，testbench 内部产生单音激励
// 输出: 控制台中文通过/失败信息
// 说明: 检查单音输入是否在预期 FFT 频点附近产生主峰

// 预期结果:
//   1. DDS 正弦单音经过 FIFO、FFT 和幅度计算后应产生 peak_valid。
//   2. peak_bin 应落在频点 8 附近，或因实信号镜像落在 248 附近。
//   3. event_tlast_missing 和 event_tlast_unexpected 都应保持为 0。
//   4. errors 保持为 0，控制台最终打印“通过：DDS 到 FFT 后处理链路的单音峰值检查正确”。

`timescale 1ns / 1ps

module tb_fft_chain;

    localparam DATA_WIDTH  = 16;
    localparam PHASE_WIDTH = 32;
    localparam FFT_SIZE    = 256;
    localparam BIN_WIDTH   = 8;

    reg clk_sample;
    reg clk_fft;
    reg rst_n;
    reg [1:0] wave_sel;
    reg [PHASE_WIDTH-1:0] freq_word;
    reg dual_tone_en;
    reg window_en;

    wire sample_rst_n;
    wire fft_rst_n;
    wire pixel_rst_n_unused;

    wire signed [DATA_WIDTH-1:0] dds_sample;
    wire dds_valid;
    wire [PHASE_WIDTH-1:0] debug_phase;
    wire signed [DATA_WIDTH-1:0] win_sample;
    wire win_valid;
    wire [7:0] win_addr;
    wire fifo_rd_en;
    wire signed [DATA_WIDTH-1:0] fifo_rd_data;
    wire fifo_rd_valid;
    wire fifo_full;
    wire fifo_empty;
    wire [9:0] fifo_wr_level;
    wire [9:0] fifo_rd_level;
    wire [2*DATA_WIDTH-1:0] fft_in_tdata;
    wire fft_in_tvalid;
    wire fft_in_tlast;
    wire fft_in_tready;
    wire frame_start;
    wire frame_done;
    wire [7:0] frame_sample_cnt;
    wire [2*DATA_WIDTH-1:0] fft_out_tdata;
    wire fft_out_tvalid;
    wire fft_out_tlast;
    wire event_tlast_missing;
    wire event_tlast_unexpected;
    wire [7:0] fft_debug_bin;
    wire [31:0] mag_data;
    wire [7:0] mag_bin;
    wire mag_valid;
    wire mag_frame_done;
    wire [7:0] peak_bin;
    wire [31:0] peak_mag;
    wire peak_valid;

    integer errors;

    clk_rst_gen u_clk_rst_gen (
        .clk_sample   (clk_sample),
        .clk_fft      (clk_fft),
        .clk_pixel    (clk_fft),
        .rst_n        (rst_n),
        .sample_rst_n (sample_rst_n),
        .fft_rst_n    (fft_rst_n),
        .pixel_rst_n  (pixel_rst_n_unused)
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
        .debug_phase_word (debug_phase)
    );

    win_mul_optional u_win_mul_optional (
        .clk_sample       (clk_sample),
        .sample_rst_n     (sample_rst_n),
        .window_en        (window_en),
        .sample_in        (dds_sample),
        .sample_in_valid  (dds_valid),
        .sample_out       (win_sample),
        .sample_out_valid (win_valid),
        .debug_coeff_addr (win_addr)
    );

    async_fifo u_async_fifo (
        .clk_wr         (clk_sample),
        .wr_rst_n       (sample_rst_n),
        .clk_rd         (clk_fft),
        .rd_rst_n       (fft_rst_n),
        .wr_en          (win_valid & ~fifo_full),
        .wr_data        (win_sample),
        .rd_en          (fifo_rd_en),
        .rd_data        (fifo_rd_data),
        .rd_valid       (fifo_rd_valid),
        .full           (fifo_full),
        .empty          (fifo_empty),
        .debug_wr_level (fifo_wr_level),
        .debug_rd_level (fifo_rd_level)
    );

    fft_frame_ctrl u_fft_frame_ctrl (
        .clk_fft           (clk_fft),
        .fft_rst_n         (fft_rst_n),
        .fifo_empty        (fifo_empty),
        .fifo_rd_data      (fifo_rd_data),
        .fifo_rd_valid     (fifo_rd_valid),
        .fft_in_ready      (fft_in_tready),
        .fifo_rd_en        (fifo_rd_en),
        .fft_s_axis_tdata  (fft_in_tdata),
        .fft_s_axis_tvalid (fft_in_tvalid),
        .fft_s_axis_tlast  (fft_in_tlast),
        .frame_start       (frame_start),
        .frame_done        (frame_done),
        .debug_sample_cnt  (frame_sample_cnt)
    );

    xfft_wrapper u_xfft_wrapper (
        .clk_fft                (clk_fft),
        .fft_rst_n              (fft_rst_n),
        .s_axis_tdata           (fft_in_tdata),
        .s_axis_tvalid          (fft_in_tvalid),
        .s_axis_tlast           (fft_in_tlast),
        .s_axis_tready          (fft_in_tready),
        .m_axis_tdata           (fft_out_tdata),
        .m_axis_tvalid          (fft_out_tvalid),
        .m_axis_tlast           (fft_out_tlast),
        .m_axis_tready          (1'b1),
        .event_tlast_missing    (event_tlast_missing),
        .event_tlast_unexpected (event_tlast_unexpected),
        .debug_out_bin          (fft_debug_bin)
    );

    fft_mag_calc u_fft_mag_calc (
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

    peak_detector u_peak_detector (
        .clk_fft        (clk_fft),
        .fft_rst_n      (fft_rst_n),
        .mag_data       (mag_data),
        .mag_bin        (mag_bin),
        .mag_valid      (mag_valid),
        .mag_frame_done (mag_frame_done),
        .peak_bin       (peak_bin),
        .peak_mag       (peak_mag),
        .peak_valid     (peak_valid)
    );

    initial begin
        clk_sample = 1'b0;
        forever #50 clk_sample = ~clk_sample;
    end

    initial begin
        clk_fft = 1'b0;
        forever #10 clk_fft = ~clk_fft;
    end

    initial begin
        rst_n = 1'b0;
        wave_sel = 2'd0;
        freq_word = 32'h0800_0000;
        dual_tone_en = 1'b0;
        window_en = 1'b0;
        errors = 0;

        repeat (10) @(posedge clk_sample);
        rst_n = 1'b1;

        wait (peak_valid);
        $display("信息：检测到峰值频点 peak_bin=%0d，峰值幅度 peak_mag=%0d",
                 peak_bin, peak_mag);

        if (!((peak_bin >= 8'd7 && peak_bin <= 8'd9)
           || (peak_bin >= 8'd247 && peak_bin <= 8'd249))) begin
            errors = errors + 1;
            $display("错误：单音主峰应接近频点 8 或镜像频点 248");
        end

        if (event_tlast_missing || event_tlast_unexpected) begin
            errors = errors + 1;
            $display("错误：FFT 输入 tlast 事件标志被置位");
        end

        if (errors == 0) begin
            $display("通过：DDS 到 FFT 后处理链路的单音峰值检查正确");
        end else begin
            $fatal(1, "失败：tb_fft_chain 共发现 %0d 个错误", errors);
        end

        $finish;
    end

endmodule
