// 模块名: ctrl_model
// 功能: 仿真用控制源，按固定节拍切换波形和演示模式
// 时钟域: clk_sample
// 输入: 复位
// 输出: 波形选择、DDS 频率控制字、双音使能、窗口使能
// 说明: 用确定性的仿真控制代替真实按键或 UART

`timescale 1ns / 1ps

module ctrl_model #(
    parameter PHASE_WIDTH = 32
) (
    input  wire                   clk_sample,
    input  wire                   sample_rst_n,
    output reg  [1:0]             wave_sel,
    output reg  [PHASE_WIDTH-1:0] freq_word,
    output reg                    dual_tone_en,
    output reg                    window_en
);

    // 演示切换时间点，单位为样本时钟周期。
    localparam [31:0] STEP_0_END = 32'd4096;
    localparam [31:0] STEP_1_END = 32'd8192;
    localparam [31:0] STEP_2_END = 32'd12288;
    localparam [31:0] STEP_3_END = 32'd16384;
    localparam [31:0] STEP_4_END = 32'd20480;

    reg [31:0] demo_cnt;

    always @(posedge clk_sample or negedge sample_rst_n) begin
        if (!sample_rst_n) begin
            demo_cnt     <= 32'd0;
            wave_sel     <= 2'd0;
            freq_word    <= 32'h0800_0000;
            dual_tone_en <= 1'b0;
            window_en    <= 1'b0;
        end else begin
            demo_cnt <= demo_cnt + 32'd1;

            if (demo_cnt < STEP_0_END) begin
                wave_sel     <= 2'd0;
                freq_word    <= 32'h0800_0000;
                dual_tone_en <= 1'b0;
                window_en    <= 1'b0;
            end else if (demo_cnt < STEP_1_END) begin
                wave_sel     <= 2'd0;
                freq_word    <= 32'h1000_0000;
                dual_tone_en <= 1'b0;
                window_en    <= 1'b1;
            end else if (demo_cnt < STEP_2_END) begin
                wave_sel     <= 2'd1;
                freq_word    <= 32'h0C00_0000;
                dual_tone_en <= 1'b0;
                window_en    <= 1'b0;
            end else if (demo_cnt < STEP_3_END) begin
                wave_sel     <= 2'd0;
                freq_word    <= 32'h0800_0000;
                dual_tone_en <= 1'b1;
                window_en    <= 1'b1;
            end else if (demo_cnt < STEP_4_END) begin
                wave_sel     <= 2'd2;
                freq_word    <= 32'h1400_0000;
                dual_tone_en <= 1'b0;
                window_en    <= 1'b0;
            end else begin
                demo_cnt     <= 32'd0;
                wave_sel     <= 2'd0;
                freq_word    <= 32'h0800_0000;
                dual_tone_en <= 1'b0;
                window_en    <= 1'b0;
            end
        end
    end

endmodule
