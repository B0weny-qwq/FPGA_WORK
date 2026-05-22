// 模块名: dds_signal_gen
// 功能: 频谱分析仪统一 DDS 信号源
// 时钟域: clk_sample
// 输入: 波形选择、频率控制字、双音使能
// 输出: 有符号样本流和固定节拍 sample_valid
// 说明: 双音模式把主波形与第二路正弦平均相加，避免溢出

`timescale 1ns / 1ps

module dds_signal_gen #(
    parameter PHASE_WIDTH = 32,
    parameter DATA_WIDTH  = 16
) (
    input  wire                         clk_sample,
    input  wire                         sample_rst_n,
    input  wire [1:0]                   wave_sel,
    input  wire [PHASE_WIDTH-1:0]       freq_word,
    input  wire                         dual_tone_en,
    output reg  signed [DATA_WIDTH-1:0] sample_data,
    output reg                          sample_valid,
    output wire [PHASE_WIDTH-1:0]       debug_phase_word
);

    localparam [1:0] WAVE_SIN = 2'd0;
    localparam [1:0] WAVE_SQR = 2'd1;
    localparam [1:0] WAVE_TRI = 2'd2;
    localparam [1:0] WAVE_SAW = 2'd3;

    wire [PHASE_WIDTH-1:0] phase_main;
    wire [PHASE_WIDTH-1:0] phase_aux;
    wire [PHASE_WIDTH-1:0] freq_word_aux;

    wire signed [DATA_WIDTH-1:0] sin_main;
    wire signed [DATA_WIDTH-1:0] sin_aux;
    wire signed [DATA_WIDTH-1:0] square_main;
    wire signed [DATA_WIDTH-1:0] triangle_main;
    wire signed [DATA_WIDTH-1:0] sawtooth_main;
    wire signed [DATA_WIDTH:0]   mix_sum;
    wire signed [DATA_WIDTH-1:0] mix_sample;

    reg signed [DATA_WIDTH-1:0] selected_sample;

    assign freq_word_aux    = freq_word + (freq_word >> 1);
    assign debug_phase_word = phase_main;
    assign mix_sum          = $signed({selected_sample[DATA_WIDTH-1], selected_sample})
                            + $signed({sin_aux[DATA_WIDTH-1], sin_aux});
    assign mix_sample       = mix_sum[DATA_WIDTH:1];

    phase_acc #(
        .PHASE_WIDTH (PHASE_WIDTH)
    ) u_phase_acc_main (
        .clk_sample   (clk_sample),
        .sample_rst_n (sample_rst_n),
        .phase_en     (1'b1),
        .freq_word    (freq_word),
        .phase_offset ({PHASE_WIDTH{1'b0}}),
        .phase_word   (phase_main)
    );

    phase_acc #(
        .PHASE_WIDTH (PHASE_WIDTH)
    ) u_phase_acc_aux (
        .clk_sample   (clk_sample),
        .sample_rst_n (sample_rst_n),
        .phase_en     (1'b1),
        .freq_word    (freq_word_aux),
        .phase_offset ({PHASE_WIDTH{1'b0}}),
        .phase_word   (phase_aux)
    );

    wave_rom_sin #(
        .PHASE_WIDTH (PHASE_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_wave_rom_sin_main (
        .clk_sample  (clk_sample),
        .phase_word  (phase_main),
        .sample_data (sin_main)
    );

    wave_rom_sin #(
        .PHASE_WIDTH (PHASE_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_wave_rom_sin_aux (
        .clk_sample  (clk_sample),
        .phase_word  (phase_aux),
        .sample_data (sin_aux)
    );

    wave_gen_square #(
        .PHASE_WIDTH (PHASE_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_wave_gen_square (
        .phase_word  (phase_main),
        .sample_data (square_main)
    );

    wave_gen_triangle #(
        .PHASE_WIDTH (PHASE_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_wave_gen_triangle (
        .phase_word  (phase_main),
        .sample_data (triangle_main)
    );

    wave_gen_sawtooth #(
        .PHASE_WIDTH (PHASE_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_wave_gen_sawtooth (
        .phase_word  (phase_main),
        .sample_data (sawtooth_main)
    );

    // 波形选择保持组合逻辑；正弦 ROM 输出有一个时钟周期延迟。
    always @(*) begin
        selected_sample = sin_main;

        case (wave_sel)
            WAVE_SIN: selected_sample = sin_main;
            WAVE_SQR: selected_sample = square_main;
            WAVE_TRI: selected_sample = triangle_main;
            WAVE_SAW: selected_sample = sawtooth_main;
            default:  selected_sample = sin_main;
        endcase
    end

    always @(posedge clk_sample or negedge sample_rst_n) begin
        if (!sample_rst_n) begin
            sample_data  <= {DATA_WIDTH{1'b0}};
            sample_valid <= 1'b0;
        end else begin
            sample_valid <= 1'b1;

            if (dual_tone_en) begin
                sample_data <= mix_sample;
            end else begin
                sample_data <= selected_sample;
            end
        end
    end

endmodule
