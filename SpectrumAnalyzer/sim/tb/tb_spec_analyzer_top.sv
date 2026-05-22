// 模块名: tb_spec_analyzer_top
// 功能: 频谱分析仪顶层端到端仿真测试
// 时钟域: clk_sample, clk_fft, clk_pixel
// 输入: 无外部输入，testbench 内部产生时钟和复位
// 输出: 控制台中文通过/失败信息
// 说明: 检查顶层链路是否产生峰值结果，FIFO 状态是否合理

// 预期结果:
//   1. 顶层复位释放后应至少检测到 2 次 debug_peak_valid。
//   2. debug_peak_mag 不能为 0，说明 DDS 到 FFT 后处理链路有有效频谱输出。
//   3. debug_fifo_full 和 debug_fifo_empty 不应同时为 1。
//   4. errors 保持为 0，控制台最终打印“通过：顶层端到端链路检查正确”。

`timescale 1ns / 1ps

module tb_spec_analyzer_top;

    reg clk_sample;
    reg clk_fft;
    reg clk_pixel;
    reg rst_n;

    wire [1:0] wave_sel;
    wire [31:0] freq_word;
    wire dual_tone_en;
    wire window_en;
    wire vga_hs;
    wire vga_vs;
    wire [3:0] vga_r;
    wire [3:0] vga_g;
    wire [3:0] vga_b;
    wire [7:0] debug_peak_bin;
    wire [31:0] debug_peak_mag;
    wire debug_peak_valid;
    wire debug_fifo_full;
    wire debug_fifo_empty;
    wire [7:0] debug_fft_bin;

    integer peak_count;
    integer errors;

    ctrl_model u_ctrl_model (
        .clk_sample   (clk_sample),
        .sample_rst_n (rst_n),
        .wave_sel     (wave_sel),
        .freq_word    (freq_word),
        .dual_tone_en (dual_tone_en),
        .window_en    (window_en)
    );

    spec_analyzer_top u_spec_analyzer_top (
        .clk_sample        (clk_sample),
        .clk_fft           (clk_fft),
        .clk_pixel         (clk_pixel),
        .rst_n             (rst_n),
        .wave_sel          (wave_sel),
        .freq_word         (freq_word),
        .dual_tone_en      (dual_tone_en),
        .window_en         (window_en),
        .vga_hs            (vga_hs),
        .vga_vs            (vga_vs),
        .vga_r             (vga_r),
        .vga_g             (vga_g),
        .vga_b             (vga_b),
        .debug_peak_bin    (debug_peak_bin),
        .debug_peak_mag    (debug_peak_mag),
        .debug_peak_valid  (debug_peak_valid),
        .debug_fifo_full   (debug_fifo_full),
        .debug_fifo_empty  (debug_fifo_empty),
        .debug_fft_bin     (debug_fft_bin)
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
        clk_pixel = 1'b0;
        forever #20 clk_pixel = ~clk_pixel;
    end

    initial begin
        rst_n = 1'b0;
        peak_count = 0;
        errors = 0;

        repeat (12) @(posedge clk_sample);
        rst_n = 1'b1;

        wait (peak_count >= 2);

        if (debug_peak_mag == 32'd0) begin
            errors = errors + 1;
            $display("错误：峰值幅度一直为 0，说明分析链路没有有效输出");
        end

        if (debug_fifo_full && debug_fifo_empty) begin
            errors = errors + 1;
            $display("错误：FIFO full 和 empty 不应同时为高");
        end

        if (errors == 0) begin
            $display("通过：顶层端到端链路检查正确");
        end else begin
            $fatal(1, "失败：tb_spec_analyzer_top 共发现 %0d 个错误", errors);
        end

        $finish;
    end

    always @(posedge clk_fft) begin
        if (debug_peak_valid) begin
            peak_count = peak_count + 1;
            $display("信息：顶层第 %0d 次峰值，频点=%0d，幅度=%0d",
                     peak_count, debug_peak_bin, debug_peak_mag);
        end
    end

endmodule
