// 模块名: fifo_wr_ctrl
// 功能: 异步 FIFO 写指针和满标志控制
// 时钟域: clk_wr
// 输入: 写请求和同步后的读 Gray 指针
// 输出: 写地址、写 Gray 指针、满标志
// 说明: 满判断使用“下一写指针”与“读指针高两位取反”比较

`timescale 1ns / 1ps

module fifo_wr_ctrl #(
    parameter ADDR_WIDTH = 9
) (
    input  wire                    clk_wr,
    input  wire                    wr_rst_n,
    input  wire                    wr_en,
    input  wire [ADDR_WIDTH:0]     rd_gray_sync,
    output wire                    wr_do,
    output wire [ADDR_WIDTH-1:0]   wr_addr,
    output reg  [ADDR_WIDTH:0]     wr_bin,
    output reg  [ADDR_WIDTH:0]     wr_gray,
    output reg                     full
);

    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    wire [PTR_WIDTH-1:0] wr_bin_next;
    wire [PTR_WIDTH-1:0] wr_gray_next;
    wire [PTR_WIDTH-1:0] full_cmp_gray;
    wire                 full_next;

    assign wr_do        = wr_en & ~full;
    assign wr_addr      = wr_bin[ADDR_WIDTH-1:0];
    assign wr_bin_next  = wr_bin + {{ADDR_WIDTH{1'b0}}, wr_do};
    assign full_cmp_gray = {~rd_gray_sync[PTR_WIDTH-1:PTR_WIDTH-2],
                            rd_gray_sync[PTR_WIDTH-3:0]};
    assign full_next    = (wr_gray_next == full_cmp_gray);

    gray_conv #(
        .WIDTH (PTR_WIDTH)
    ) u_gray_conv_wr (
        .bin_in   (wr_bin_next),
        .gray_in  ({PTR_WIDTH{1'b0}}),
        .gray_out (wr_gray_next),
        .bin_out  ()
    );

    always @(posedge clk_wr or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= {PTR_WIDTH{1'b0}};
            wr_gray <= {PTR_WIDTH{1'b0}};
            full    <= 1'b0;
        end else begin
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
            full    <= full_next;
        end
    end

endmodule
