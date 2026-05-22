// 模块名: async_fifo
// 功能: 样本域到 FFT 域的异步 FIFO 顶层封装
// 时钟域: clk_wr 和 clk_rd
// 输入: 简单写/读请求
// 输出: full、empty、注册读数据和 rd_valid
// 说明: 使用 Gray 指针同步保护跨时钟域边界

`timescale 1ns / 1ps

module async_fifo #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 9
) (
    input  wire                         clk_wr,
    input  wire                         wr_rst_n,
    input  wire                         clk_rd,
    input  wire                         rd_rst_n,
    input  wire                         wr_en,
    input  wire signed [DATA_WIDTH-1:0] wr_data,
    input  wire                         rd_en,
    output wire signed [DATA_WIDTH-1:0] rd_data,
    output reg                          rd_valid,
    output wire                         full,
    output wire                         empty,
    output wire [ADDR_WIDTH:0]          debug_wr_level,
    output wire [ADDR_WIDTH:0]          debug_rd_level
);

    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    wire                  wr_do;
    wire                  rd_do;
    wire [ADDR_WIDTH-1:0] wr_addr;
    wire [ADDR_WIDTH-1:0] rd_addr;
    wire [PTR_WIDTH-1:0]  wr_bin;
    wire [PTR_WIDTH-1:0]  rd_bin;
    wire [PTR_WIDTH-1:0]  wr_gray;
    wire [PTR_WIDTH-1:0]  rd_gray;
    wire [PTR_WIDTH-1:0]  wr_gray_sync_rd;
    wire [PTR_WIDTH-1:0]  rd_gray_sync_wr;
    wire [PTR_WIDTH-1:0]  wr_bin_sync_rd;
    wire [PTR_WIDTH-1:0]  rd_bin_sync_wr;

    assign debug_wr_level = wr_bin - rd_bin_sync_wr;
    assign debug_rd_level = wr_bin_sync_rd - rd_bin;

    fifo_mem #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_fifo_mem (
        .clk_wr  (clk_wr),
        .clk_rd  (clk_rd),
        .wr_en   (wr_do),
        .wr_addr (wr_addr),
        .wr_data (wr_data),
        .rd_en   (rd_do),
        .rd_addr (rd_addr),
        .rd_data (rd_data)
    );

    fifo_wr_ctrl #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_fifo_wr_ctrl (
        .clk_wr       (clk_wr),
        .wr_rst_n     (wr_rst_n),
        .wr_en        (wr_en),
        .rd_gray_sync (rd_gray_sync_wr),
        .wr_do        (wr_do),
        .wr_addr      (wr_addr),
        .wr_bin       (wr_bin),
        .wr_gray      (wr_gray),
        .full         (full)
    );

    fifo_rd_ctrl #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_fifo_rd_ctrl (
        .clk_rd       (clk_rd),
        .rd_rst_n     (rd_rst_n),
        .rd_en        (rd_en),
        .wr_gray_sync (wr_gray_sync_rd),
        .rd_do        (rd_do),
        .rd_addr      (rd_addr),
        .rd_bin       (rd_bin),
        .rd_gray      (rd_gray),
        .empty        (empty)
    );

    gray_sync #(
        .WIDTH (PTR_WIDTH)
    ) u_gray_sync_wr_to_rd (
        .clk      (clk_rd),
        .rst_n    (rd_rst_n),
        .gray_in  (wr_gray),
        .gray_out (wr_gray_sync_rd)
    );

    gray_sync #(
        .WIDTH (PTR_WIDTH)
    ) u_gray_sync_rd_to_wr (
        .clk      (clk_wr),
        .rst_n    (wr_rst_n),
        .gray_in  (rd_gray),
        .gray_out (rd_gray_sync_wr)
    );

    gray_conv #(
        .WIDTH (PTR_WIDTH)
    ) u_gray_conv_wr_sync (
        .bin_in   ({PTR_WIDTH{1'b0}}),
        .gray_in  (wr_gray_sync_rd),
        .gray_out (),
        .bin_out  (wr_bin_sync_rd)
    );

    gray_conv #(
        .WIDTH (PTR_WIDTH)
    ) u_gray_conv_rd_sync (
        .bin_in   ({PTR_WIDTH{1'b0}}),
        .gray_in  (rd_gray_sync_wr),
        .gray_out (),
        .bin_out  (rd_bin_sync_wr)
    );

    always @(posedge clk_rd or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_valid <= 1'b0;
        end else begin
            rd_valid <= rd_do;
        end
    end

endmodule
