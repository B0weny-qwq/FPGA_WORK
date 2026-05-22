// 模块名: gray_conv
// 功能: FIFO 指针二进制码和 Gray 码互相转换
// 时钟域: 组合逻辑
// 输入: 二进制向量和 Gray 向量
// 输出: 转换后的 Gray 向量和二进制向量
// 说明: Gray 指针跨时钟域时每次只变化一位，可降低同步风险

`timescale 1ns / 1ps

module gray_conv #(
    parameter WIDTH = 10
) (
    input  wire [WIDTH-1:0] bin_in,
    input  wire [WIDTH-1:0] gray_in,
    output wire [WIDTH-1:0] gray_out,
    output reg  [WIDTH-1:0] bin_out
);

    integer bit_idx;

    assign gray_out = (bin_in >> 1) ^ bin_in;

    always @(*) begin
        bin_out[WIDTH-1] = gray_in[WIDTH-1];

        for (bit_idx = WIDTH - 2; bit_idx >= 0; bit_idx = bit_idx - 1) begin
            bin_out[bit_idx] = bin_out[bit_idx + 1] ^ gray_in[bit_idx];
        end
    end

endmodule
