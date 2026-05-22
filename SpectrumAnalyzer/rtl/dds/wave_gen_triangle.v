// 模块名: wave_gen_triangle
// 功能: 根据 DDS 相位产生三角波
// 时钟域: DDS 组合数据通路
// 输入: phase_word
// 输出: 有符号三角波样本
// 说明: 前半周期上升，后半周期下降，适合展示非正弦频谱

`timescale 1ns / 1ps

module wave_gen_triangle #(
    parameter PHASE_WIDTH = 32,
    parameter DATA_WIDTH  = 16
) (
    input  wire [PHASE_WIDTH-1:0]       phase_word,
    output reg  signed [DATA_WIDTH-1:0] sample_data
);

    localparam AMP_MSB = PHASE_WIDTH - 2;
    localparam AMP_LSB = PHASE_WIDTH - DATA_WIDTH - 1;

    wire [DATA_WIDTH-1:0] ramp_unsigned;
    reg  signed [DATA_WIDTH:0] ramp_signed;

    assign ramp_unsigned = phase_word[AMP_MSB:AMP_LSB];

    always @(*) begin
        if (!phase_word[PHASE_WIDTH-1]) begin
            ramp_signed = $signed({1'b0, ramp_unsigned}) - (2 ** (DATA_WIDTH - 1));
        end else begin
            ramp_signed = ((2 ** (DATA_WIDTH - 1)) - 1) - $signed({1'b0, ramp_unsigned});
        end

        sample_data = ramp_signed[DATA_WIDTH-1:0];
    end

endmodule
