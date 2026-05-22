// 模块名: fifo_mem
// 功能: 异步 FIFO 的双时钟存储阵列
// 时钟域: clk_wr 写入，clk_rd 注册读出
// 输入: 读写地址和使能
// 输出: 注册后的读数据
// 说明: 读请求被接受后的下一个读时钟周期，rd_data 才有效

`timescale 1ns / 1ps

module fifo_mem #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 9
) (
    input  wire                         clk_wr,
    input  wire                         clk_rd,
    input  wire                         wr_en,
    input  wire [ADDR_WIDTH-1:0]        wr_addr,
    input  wire signed [DATA_WIDTH-1:0] wr_data,
    input  wire                         rd_en,
    input  wire [ADDR_WIDTH-1:0]        rd_addr,
    output reg  signed [DATA_WIDTH-1:0] rd_data
);

    localparam FIFO_DEPTH = (1 << ADDR_WIDTH);

    // 存储体可由工具推断为分布式 RAM 或块 RAM。
    reg signed [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    always @(posedge clk_wr) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    always @(posedge clk_rd) begin
        if (rd_en) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule
