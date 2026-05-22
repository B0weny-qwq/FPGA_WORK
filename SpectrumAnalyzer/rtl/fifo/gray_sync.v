// 模块名: gray_sync
// 功能: 将 Gray 编码指针同步到目标时钟域
// 时钟域: 目标 clk
// 输入: 异步 Gray 指针
// 输出: 同步后的 Gray 指针
// 说明: FIFO 跨时钟域只同步 Gray 指针，不直接同步二进制指针

`timescale 1ns / 1ps

module gray_sync #(
    parameter WIDTH = 10
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] gray_in,
    output reg  [WIDTH-1:0] gray_out
);

    // 两级同步链用于跨时钟域传递 Gray 指针。
    reg [WIDTH-1:0] gray_meta;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_meta <= {WIDTH{1'b0}};
            gray_out  <= {WIDTH{1'b0}};
        end else begin
            gray_meta <= gray_in;
            gray_out  <= gray_meta;
        end
    end

endmodule
