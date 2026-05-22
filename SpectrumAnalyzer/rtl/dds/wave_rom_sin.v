// 模块名: wave_rom_sin
// 功能: DDS 正弦查找表
// 时钟域: clk_sample
// 输入: phase_word
// 输出: 有符号正弦样本
// 说明: 使用四分之一波形整数查表，避免综合时依赖行为级数学函数初始化

`timescale 1ns / 1ps

module wave_rom_sin #(
    parameter PHASE_WIDTH = 32,
    parameter ADDR_WIDTH  = 8,
    parameter DATA_WIDTH  = 16
) (
    input  wire                         clk_sample,
    input  wire [PHASE_WIDTH-1:0]       phase_word,
    output reg  signed [DATA_WIDTH-1:0] sample_data
);

    localparam ADDR_LSB = PHASE_WIDTH - ADDR_WIDTH;

    wire [ADDR_WIDTH-1:0] rom_addr;
    wire [5:0] quarter_idx;
    wire [6:0] mirror_idx;
    reg  signed [15:0] quarter_sample;
    reg  signed [15:0] sine_sample;

    assign rom_addr = phase_word[PHASE_WIDTH-1:ADDR_LSB];
    assign quarter_idx = rom_addr[5:0];
    assign mirror_idx = rom_addr[6] ? ({1'b1, {6{1'b0}}} - {1'b0, quarter_idx})
                                   : {1'b0, quarter_idx};

    always @(*) begin
        case (mirror_idx)
            7'd0: quarter_sample = 16'sd0;
            7'd1: quarter_sample = 16'sd804;
            7'd2: quarter_sample = 16'sd1607;
            7'd3: quarter_sample = 16'sd2410;
            7'd4: quarter_sample = 16'sd3211;
            7'd5: quarter_sample = 16'sd4011;
            7'd6: quarter_sample = 16'sd4807;
            7'd7: quarter_sample = 16'sd5601;
            7'd8: quarter_sample = 16'sd6392;
            7'd9: quarter_sample = 16'sd7179;
            7'd10: quarter_sample = 16'sd7961;
            7'd11: quarter_sample = 16'sd8739;
            7'd12: quarter_sample = 16'sd9511;
            7'd13: quarter_sample = 16'sd10278;
            7'd14: quarter_sample = 16'sd11038;
            7'd15: quarter_sample = 16'sd11792;
            7'd16: quarter_sample = 16'sd12539;
            7'd17: quarter_sample = 16'sd13278;
            7'd18: quarter_sample = 16'sd14009;
            7'd19: quarter_sample = 16'sd14732;
            7'd20: quarter_sample = 16'sd15446;
            7'd21: quarter_sample = 16'sd16150;
            7'd22: quarter_sample = 16'sd16845;
            7'd23: quarter_sample = 16'sd17530;
            7'd24: quarter_sample = 16'sd18204;
            7'd25: quarter_sample = 16'sd18867;
            7'd26: quarter_sample = 16'sd19519;
            7'd27: quarter_sample = 16'sd20159;
            7'd28: quarter_sample = 16'sd20787;
            7'd29: quarter_sample = 16'sd21402;
            7'd30: quarter_sample = 16'sd22004;
            7'd31: quarter_sample = 16'sd22594;
            7'd32: quarter_sample = 16'sd23169;
            7'd33: quarter_sample = 16'sd23731;
            7'd34: quarter_sample = 16'sd24278;
            7'd35: quarter_sample = 16'sd24811;
            7'd36: quarter_sample = 16'sd25329;
            7'd37: quarter_sample = 16'sd25831;
            7'd38: quarter_sample = 16'sd26318;
            7'd39: quarter_sample = 16'sd26789;
            7'd40: quarter_sample = 16'sd27244;
            7'd41: quarter_sample = 16'sd27683;
            7'd42: quarter_sample = 16'sd28105;
            7'd43: quarter_sample = 16'sd28510;
            7'd44: quarter_sample = 16'sd28897;
            7'd45: quarter_sample = 16'sd29268;
            7'd46: quarter_sample = 16'sd29621;
            7'd47: quarter_sample = 16'sd29955;
            7'd48: quarter_sample = 16'sd30272;
            7'd49: quarter_sample = 16'sd30571;
            7'd50: quarter_sample = 16'sd30851;
            7'd51: quarter_sample = 16'sd31113;
            7'd52: quarter_sample = 16'sd31356;
            7'd53: quarter_sample = 16'sd31580;
            7'd54: quarter_sample = 16'sd31785;
            7'd55: quarter_sample = 16'sd31970;
            7'd56: quarter_sample = 16'sd32137;
            7'd57: quarter_sample = 16'sd32284;
            7'd58: quarter_sample = 16'sd32412;
            7'd59: quarter_sample = 16'sd32520;
            7'd60: quarter_sample = 16'sd32609;
            7'd61: quarter_sample = 16'sd32678;
            7'd62: quarter_sample = 16'sd32727;
            7'd63: quarter_sample = 16'sd32757;
            7'd64: quarter_sample = 16'sd32767;
            default: quarter_sample = 16'sd0;
        endcase

        if (rom_addr[7]) begin
            sine_sample = -quarter_sample;
        end else begin
            sine_sample = quarter_sample;
        end
    end

    always @(posedge clk_sample) begin
        sample_data <= sine_sample;
    end

endmodule
