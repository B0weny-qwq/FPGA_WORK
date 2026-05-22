// 模块名: vga_timing_gen
// 功能: 产生 640x480 VGA 风格时序和当前像素坐标
// 时钟域: clk_pixel
// 输入: 复位
// 输出: HS/VS、有效显示标志、当前 x/y 坐标
// 说明: 使用 25 MHz、640x480@60 的常用仿真时序参数

`timescale 1ns / 1ps

module vga_timing_gen #(
    parameter H_ACTIVE = 640,
    parameter H_FP     = 16,
    parameter H_SYNC   = 96,
    parameter H_BP     = 48,
    parameter V_ACTIVE = 480,
    parameter V_FP     = 10,
    parameter V_SYNC   = 2,
    parameter V_BP     = 33
) (
    input  wire        clk_pixel,
    input  wire        pixel_rst_n,
    output reg         vga_hs,
    output reg         vga_vs,
    output reg         active_video,
    output reg  [9:0]  pixel_x,
    output reg  [9:0]  pixel_y,
    output reg         frame_tick
);

    localparam H_TOTAL      = H_ACTIVE + H_FP + H_SYNC + H_BP;
    localparam V_TOTAL      = V_ACTIVE + V_FP + V_SYNC + V_BP;
    localparam H_SYNC_BEGIN = H_ACTIVE + H_FP;
    localparam H_SYNC_END   = H_ACTIVE + H_FP + H_SYNC;
    localparam V_SYNC_BEGIN = V_ACTIVE + V_FP;
    localparam V_SYNC_END   = V_ACTIVE + V_FP + V_SYNC;
    localparam [9:0] H_TOTAL_COUNT      = H_TOTAL;
    localparam [9:0] V_TOTAL_COUNT      = V_TOTAL;
    localparam [9:0] H_ACTIVE_COUNT     = H_ACTIVE;
    localparam [9:0] V_ACTIVE_COUNT     = V_ACTIVE;
    localparam [9:0] H_SYNC_BEGIN_COUNT = H_SYNC_BEGIN;
    localparam [9:0] H_SYNC_END_COUNT   = H_SYNC_END;
    localparam [9:0] V_SYNC_BEGIN_COUNT = V_SYNC_BEGIN;
    localparam [9:0] V_SYNC_END_COUNT   = V_SYNC_END;

    // VGA 扫描计数器：先行计数，再场计数。
    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    always @(posedge clk_pixel or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin
            h_cnt <= 10'd0;
            v_cnt <= 10'd0;
            frame_tick <= 1'b0;
        end else begin
            frame_tick <= 1'b0;

            if (h_cnt == H_TOTAL_COUNT - 1'b1) begin
                h_cnt <= 10'd0;

                if (v_cnt == V_TOTAL_COUNT - 1'b1) begin
                    v_cnt <= 10'd0;
                    frame_tick <= 1'b1;
                end else begin
                    v_cnt <= v_cnt + 10'd1;
                end
            end else begin
                h_cnt <= h_cnt + 10'd1;
            end
        end
    end

    always @(posedge clk_pixel or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin
            vga_hs <= 1'b1;
            vga_vs <= 1'b1;
            active_video <= 1'b0;
            pixel_x <= 10'd0;
            pixel_y <= 10'd0;
        end else begin
            vga_hs <= ~((h_cnt >= H_SYNC_BEGIN_COUNT) && (h_cnt < H_SYNC_END_COUNT));
            vga_vs <= ~((v_cnt >= V_SYNC_BEGIN_COUNT) && (v_cnt < V_SYNC_END_COUNT));
            active_video <= (h_cnt < H_ACTIVE_COUNT) && (v_cnt < V_ACTIVE_COUNT);
            pixel_x <= h_cnt;
            pixel_y <= v_cnt;
        end
    end

endmodule
