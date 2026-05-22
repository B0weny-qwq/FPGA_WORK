// 模块名: mag_compress
// 功能: 将原始 FFT 功率幅度压缩成显示等级
// 时钟域: clk_fft
// 输入: 原始幅度流
// 输出: 限幅后的显示等级流
// 说明: 使用分段移位压缩，保持单调性且不需要除法器

`timescale 1ns / 1ps

module mag_compress #(
    parameter MAG_WIDTH   = 32,
    parameter LEVEL_WIDTH = 8,
    parameter BIN_WIDTH   = 8,
    parameter MAX_LEVEL   = 200
) (
    input  wire                   clk_fft,
    input  wire                   fft_rst_n,
    input  wire [MAG_WIDTH-1:0]   mag_data,
    input  wire [BIN_WIDTH-1:0]   mag_bin,
    input  wire                   mag_valid,
    input  wire                   mag_frame_done,
    output reg  [LEVEL_WIDTH-1:0] level_data,
    output reg  [BIN_WIDTH-1:0]   level_bin,
    output reg                    level_valid,
    output reg                    level_frame_done
);

    localparam [LEVEL_WIDTH+3:0] MAX_LEVEL_EXT = MAX_LEVEL;

    reg [LEVEL_WIDTH+3:0] level_nxt;

    always @(*) begin
        if (mag_data[31:28] != 4'd0) begin
            level_nxt = {4'd0, mag_data[31:28], mag_data[27:24]};
        end else if (mag_data[27:20] != 8'd0) begin
            level_nxt = {2'd0, mag_data[27:20], 2'd0};
        end else if (mag_data[19:12] != 8'd0) begin
            level_nxt = {1'd0, mag_data[19:12], 3'd0};
        end else begin
            level_nxt = {mag_data[11:4], 4'd0};
        end

        if (level_nxt > MAX_LEVEL_EXT) begin
            level_nxt = MAX_LEVEL_EXT;
        end
    end

    always @(posedge clk_fft or negedge fft_rst_n) begin
        if (!fft_rst_n) begin
            level_data <= {LEVEL_WIDTH{1'b0}};
            level_bin <= {BIN_WIDTH{1'b0}};
            level_valid <= 1'b0;
            level_frame_done <= 1'b0;
        end else begin
            level_valid <= mag_valid;
            level_frame_done <= mag_frame_done & mag_valid;

            if (mag_valid) begin
                level_data <= level_nxt[LEVEL_WIDTH-1:0];
                level_bin <= mag_bin;
            end
        end
    end

endmodule
