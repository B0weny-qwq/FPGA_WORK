// 模块名: spectrum_renderer
// 功能: 根据频点缓存值渲染频谱柱状图 RGB 图层
// 时钟域: clk_pixel
// 输入: 当前 VGA 坐标和频点等级
// 输出: 频点读取地址和频谱图层 RGB
// 说明: 将绘图区横向映射到 DISPLAY_BINS 个频点

`timescale 1ns / 1ps

module spectrum_renderer #(
    parameter H_ACTIVE     = 640,
    parameter V_ACTIVE     = 480,
    parameter DISPLAY_BINS = 128,
    parameter READ_ADDR_W  = 7,
    parameter LEVEL_WIDTH  = 8,
    parameter BAR_MAX_H    = 220
) (
    input  wire                   clk_pixel,
    input  wire                   pixel_rst_n,
    input  wire                   active_video,
    input  wire [9:0]             pixel_x,
    input  wire [9:0]             pixel_y,
    input  wire [LEVEL_WIDTH-1:0] bin_level,
    output reg  [READ_ADDR_W-1:0] bin_rd_addr,
    output reg  [11:0]            spectrum_rgb,
    output reg                    spectrum_on
);

    localparam PLOT_LEFT   = 10'd32;
    localparam PLOT_RIGHT  = 10'd608;
    localparam PLOT_TOP    = 10'd96;
    localparam PLOT_BOTTOM = 10'd384;
    localparam PLOT_WIDTH  = PLOT_RIGHT - PLOT_LEFT;

    wire [8:0] bar_height;
    wire [9:0] plot_x;
    wire [16:0] bin_index_scaled;
    wire [9:0] bin_index_wide;
    wire       in_plot_x;
    wire       in_plot_y;
    wire       bar_pixel;
    wire       grid_pixel;

    assign in_plot_x = (pixel_x >= PLOT_LEFT) && (pixel_x < PLOT_RIGHT);
    assign in_plot_y = (pixel_y >= PLOT_TOP) && (pixel_y < PLOT_BOTTOM);
    assign plot_x = pixel_x - PLOT_LEFT;
    assign bin_index_scaled = plot_x * DISPLAY_BINS;
    assign bin_index_wide = bin_index_scaled / PLOT_WIDTH;
    assign bar_pixel = in_plot_x && in_plot_y
                     && (pixel_y >= (PLOT_BOTTOM - bar_height));
    assign grid_pixel = in_plot_x && in_plot_y
                      && (((pixel_y - PLOT_TOP) % 10'd48) == 10'd0);

    bin_to_height #(
        .LEVEL_WIDTH  (LEVEL_WIDTH),
        .HEIGHT_WIDTH (9),
        .MAX_HEIGHT   (BAR_MAX_H)
    ) u_bin_to_height (
        .level_data (bin_level),
        .bar_height (bar_height)
    );

    always @(posedge clk_pixel or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin
            bin_rd_addr <= {READ_ADDR_W{1'b0}};
            spectrum_rgb <= 12'h000;
            spectrum_on <= 1'b0;
        end else begin
            if (in_plot_x) begin
                bin_rd_addr <= bin_index_wide[READ_ADDR_W-1:0];
            end else begin
                bin_rd_addr <= {READ_ADDR_W{1'b0}};
            end

            spectrum_on <= active_video && (bar_pixel || grid_pixel);

            if (!active_video) begin
                spectrum_rgb <= 12'h000;
            end else if (bar_pixel) begin
                spectrum_rgb <= 12'h2E7;
            end else if (grid_pixel) begin
                spectrum_rgb <= 12'h244;
            end else begin
                spectrum_rgb <= 12'h013;
            end
        end
    end

endmodule
