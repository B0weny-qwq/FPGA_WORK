// 模块名: spec_bin_buffer
// 功能: 保存压缩后的频谱显示等级，供 VGA 读取
// 时钟域: clk_fft 写侧，clk_pixel 读侧
// 输入: 压缩频点和 VGA 读取地址
// 输出: 注册后的显示等级
// 说明: 只保存前 128 个可视频点，对应实信号频谱的前半部分

`timescale 1ns / 1ps

module spec_bin_buffer #(
    parameter BIN_WIDTH     = 8,
    parameter LEVEL_WIDTH   = 8,
    parameter DISPLAY_BINS  = 128,
    parameter READ_ADDR_W   = 7
) (
    input  wire                    clk_fft,
    input  wire                    fft_rst_n,
    input  wire [BIN_WIDTH-1:0]    level_bin,
    input  wire [LEVEL_WIDTH-1:0]  level_data,
    input  wire                    level_valid,
    input  wire                    level_frame_done,
    input  wire                    clk_pixel,
    input  wire                    pixel_rst_n,
    input  wire [READ_ADDR_W-1:0]  rd_bin,
    output reg  [LEVEL_WIDTH-1:0]  rd_level,
    output reg                     frame_toggle
);

    localparam [BIN_WIDTH-1:0] DISPLAY_BINS_VALUE = DISPLAY_BINS;

    reg [LEVEL_WIDTH-1:0] level_mem [0:DISPLAY_BINS-1];

    integer init_idx;

    initial begin
        for (init_idx = 0; init_idx < DISPLAY_BINS; init_idx = init_idx + 1) begin
            level_mem[init_idx] = {LEVEL_WIDTH{1'b0}};
        end
    end

    always @(posedge clk_fft or negedge fft_rst_n) begin
        if (!fft_rst_n) begin
            frame_toggle <= 1'b0;
        end else begin
            if (level_valid && (level_bin < DISPLAY_BINS_VALUE)) begin
                level_mem[level_bin[READ_ADDR_W-1:0]] <= level_data;
            end

            if (level_frame_done) begin
                frame_toggle <= ~frame_toggle;
            end
        end
    end

    always @(posedge clk_pixel or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin
            rd_level <= {LEVEL_WIDTH{1'b0}};
        end else begin
            rd_level <= level_mem[rd_bin];
        end
    end

endmodule
