// 模块名: overlay_mux
// 功能: 合成背景、频谱和 OSD 图层，输出最终 VGA RGB
// 时钟域: clk_pixel
// 输入: 有效显示标志和各图层 RGB
// 输出: 最终 VGA RGB
// 说明: OSD 优先级最高，其次是频谱，最后是背景

`timescale 1ns / 1ps

module overlay_mux (
    input  wire        clk_pixel,
    input  wire        pixel_rst_n,
    input  wire        active_video,
    input  wire [11:0] spectrum_rgb,
    input  wire        spectrum_on,
    input  wire [11:0] osd_rgb,
    input  wire        osd_on,
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b
);

    reg [11:0] rgb_next;

    always @(*) begin
        rgb_next = 12'h012;

        if (!active_video) begin
            rgb_next = 12'h000;
        end else if (osd_on) begin
            rgb_next = osd_rgb;
        end else if (spectrum_on) begin
            rgb_next = spectrum_rgb;
        end
    end

    always @(posedge clk_pixel or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end else begin
            vga_r <= rgb_next[11:8];
            vga_g <= rgb_next[7:4];
            vga_b <= rgb_next[3:0];
        end
    end

endmodule
