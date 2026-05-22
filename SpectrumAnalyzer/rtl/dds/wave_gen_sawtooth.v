// 模块名: wave_gen_sawtooth
// 功能: 根据 DDS 相位产生锯齿波
// 时钟域: DDS 组合数据通路
// 输入: phase_word
// 输出: 有符号锯齿波样本
// 说明: 使用相位高位映射成一个周期内的线性斜坡

`timescale 1ns / 1ps

module wave_gen_sawtooth #(
    parameter PHASE_WIDTH = 32,
    parameter DATA_WIDTH  = 16
) (
    input  wire [PHASE_WIDTH-1:0]       phase_word,
    output reg  signed [DATA_WIDTH-1:0] sample_data
);

    localparam AMP_MSB = PHASE_WIDTH - 1;
    localparam AMP_LSB = PHASE_WIDTH - DATA_WIDTH;

    wire [DATA_WIDTH-1:0] ramp_unsigned;
    reg  signed [DATA_WIDTH:0] ramp_signed;

    assign ramp_unsigned = phase_word[AMP_MSB:AMP_LSB];

    always @(*) begin
        ramp_signed = $signed({1'b0, ramp_unsigned}) - (2 ** (DATA_WIDTH - 1));
        sample_data = ramp_signed[DATA_WIDTH-1:0];
    end

endmodule
