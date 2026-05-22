// 模块名: wave_gen_square
// 功能: 根据 DDS 相位产生方波
// 时钟域: DDS 组合数据通路
// 输入: phase_word
// 输出: 有符号方波样本
// 说明: 根据相位最高位判断正负半周，占空比约为 50%

`timescale 1ns / 1ps

module wave_gen_square #(
    parameter PHASE_WIDTH = 32,
    parameter DATA_WIDTH  = 16
) (
    input  wire [PHASE_WIDTH-1:0]       phase_word,
    output reg  signed [DATA_WIDTH-1:0] sample_data
);

    localparam signed [DATA_WIDTH-1:0] POS_LEVEL =  (2 ** (DATA_WIDTH - 1)) - 1;
    localparam signed [DATA_WIDTH-1:0] NEG_LEVEL = -(2 ** (DATA_WIDTH - 1)) + 1;

    always @(*) begin
        if (phase_word[PHASE_WIDTH-1]) begin
            sample_data = NEG_LEVEL;
        end else begin
            sample_data = POS_LEVEL;
        end
    end

endmodule
