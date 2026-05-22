// 模块名: phase_acc
// 功能: DDS 相位累加器
// 时钟域: clk_sample
// 输入: freq_word, phase_offset, phase_en
// 输出: phase_word
// 说明: 相位自然溢出回绕，输出相位额外叠加 phase_offset

`timescale 1ns / 1ps

module phase_acc #(
    parameter PHASE_WIDTH = 32
) (
    input  wire                   clk_sample,
    input  wire                   sample_rst_n,
    input  wire                   phase_en,
    input  wire [PHASE_WIDTH-1:0] freq_word,
    input  wire [PHASE_WIDTH-1:0] phase_offset,
    output wire [PHASE_WIDTH-1:0] phase_word
);

    // 相位累加寄存器，freq_word 决定输出波形频率。
    reg [PHASE_WIDTH-1:0] phase_accum;

    assign phase_word = phase_accum + phase_offset;

    always @(posedge clk_sample or negedge sample_rst_n) begin
        if (!sample_rst_n) begin
            phase_accum <= {PHASE_WIDTH{1'b0}};
        end else if (phase_en) begin
            phase_accum <= phase_accum + freq_word;
        end
    end

endmodule
