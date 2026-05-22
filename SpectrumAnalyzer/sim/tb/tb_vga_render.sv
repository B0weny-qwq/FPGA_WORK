// 模块名: tb_vga_render
// 功能: VGA 时序和频谱渲染独立仿真测试
// 时钟域: clk_pixel
// 输入: 无外部输入，testbench 内部构造频点等级
// 输出: 控制台中文通过/失败信息
// 说明: 检查一帧有效像素数量和频谱图层是否有输出

// 预期结果:
//   1. 一帧 active_video 像素计数应等于 640 * 480。
//   2. spectrum_on 至少出现一次，说明频谱柱状图或网格图层有输出。
//   3. errors 保持为 0。
//   4. 控制台最终打印“通过：VGA 时序和频谱渲染检查正确”。

`timescale 1ns / 1ps

module tb_vga_render;

    reg clk_pixel;
    reg pixel_rst_n;
    wire vga_hs;
    wire vga_vs;
    wire active_video;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire frame_tick;
    wire [6:0] bin_rd_addr;
    reg [7:0] bin_level;
    wire [11:0] spectrum_rgb;
    wire spectrum_on;

    integer active_count;
    integer bar_pixels;
    integer errors;

    vga_timing_gen u_vga_timing_gen (
        .clk_pixel    (clk_pixel),
        .pixel_rst_n  (pixel_rst_n),
        .vga_hs       (vga_hs),
        .vga_vs       (vga_vs),
        .active_video (active_video),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .frame_tick   (frame_tick)
    );

    spectrum_renderer u_spectrum_renderer (
        .clk_pixel    (clk_pixel),
        .pixel_rst_n  (pixel_rst_n),
        .active_video (active_video),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .bin_level    (bin_level),
        .bin_rd_addr  (bin_rd_addr),
        .spectrum_rgb (spectrum_rgb),
        .spectrum_on  (spectrum_on)
    );

    initial begin
        clk_pixel = 1'b0;
        forever #20 clk_pixel = ~clk_pixel;
    end

    always @(*) begin
        bin_level = {1'b0, bin_rd_addr};
    end

    initial begin
        pixel_rst_n = 1'b0;
        active_count = 0;
        bar_pixels = 0;
        errors = 0;

        repeat (8) @(posedge clk_pixel);
        pixel_rst_n = 1'b1;

        wait (frame_tick);

        if (active_count != 640 * 480) begin
            errors = errors + 1;
            $display("错误：有效像素数量应为 %0d，实际为 %0d", 640 * 480, active_count);
        end

        if (bar_pixels == 0) begin
            errors = errors + 1;
            $display("错误：频谱渲染器没有产生任何频谱或网格像素");
        end

        if (errors == 0) begin
            $display("通过：VGA 时序和频谱渲染检查正确");
        end else begin
            $fatal(1, "失败：tb_vga_render 共发现 %0d 个错误", errors);
        end

        $finish;
    end

    always @(posedge clk_pixel) begin
        if (active_video) begin
            active_count = active_count + 1;
        end

        if (spectrum_on) begin
            bar_pixels = bar_pixels + 1;
        end
    end

endmodule
