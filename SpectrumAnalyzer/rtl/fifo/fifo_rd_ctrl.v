// 模块名: fifo_rd_ctrl
// 功能: 异步 FIFO 读指针和空标志控制
// 时钟域: clk_rd
// 输入: 读请求和同步后的写 Gray 指针
// 输出: 读地址、读 Gray 指针、空标志
// 说明: 空判断使用“下一读指针”与同步后的写指针比较

`timescale 1ns / 1ps

module fifo_rd_ctrl #(
    parameter ADDR_WIDTH = 9
) (
    input  wire                    clk_rd,
    input  wire                    rd_rst_n,
    input  wire                    rd_en,
    input  wire [ADDR_WIDTH:0]     wr_gray_sync,
    output wire                    rd_do,
    output wire [ADDR_WIDTH-1:0]   rd_addr,
    output reg  [ADDR_WIDTH:0]     rd_bin,
    output reg  [ADDR_WIDTH:0]     rd_gray,
    output reg                     empty
);

    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    wire [PTR_WIDTH-1:0] rd_bin_next;
    wire [PTR_WIDTH-1:0] rd_gray_next;
    wire                 empty_next;

    assign rd_do       = rd_en & ~empty;
    assign rd_addr     = rd_bin[ADDR_WIDTH-1:0];
    assign rd_bin_next = rd_bin + {{ADDR_WIDTH{1'b0}}, rd_do};
    assign empty_next  = (rd_gray_next == wr_gray_sync);

    gray_conv #(
        .WIDTH (PTR_WIDTH)
    ) u_gray_conv_rd (
        .bin_in   (rd_bin_next),
        .gray_in  ({PTR_WIDTH{1'b0}}),
        .gray_out (rd_gray_next),
        .bin_out  ()
    );

    always @(posedge clk_rd or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin  <= {PTR_WIDTH{1'b0}};
            rd_gray <= {PTR_WIDTH{1'b0}};
            empty   <= 1'b1;
        end else begin
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
            empty   <= empty_next;
        end
    end

endmodule
