// 模块名: hann_rom
// 功能: 256 点 Hann 窗系数 ROM
// 时钟域: clk_sample 数据通路中的组合查找
// 输入: 系数地址
// 输出: 无符号 Q1.15 系数
// 说明: 使用半窗整数查表，避免综合时依赖行为级数学函数初始化

`timescale 1ns / 1ps

module hann_rom #(
    parameter ADDR_WIDTH  = 8,
    parameter COEFF_WIDTH = 16
) (
    input  wire [ADDR_WIDTH-1:0]      addr,
    output reg  [COEFF_WIDTH-1:0]     coeff
);

    wire [6:0] half_addr;
    reg  [15:0] half_coeff;

    assign half_addr = addr[7] ? (7'd127 - addr[6:0]) : addr[6:0];

    always @(*) begin
        case (half_addr)
            7'd0: half_coeff = 16'd0;
            7'd1: half_coeff = 16'd4;
            7'd2: half_coeff = 16'd19;
            7'd3: half_coeff = 16'd44;
            7'd4: half_coeff = 16'd79;
            7'd5: half_coeff = 16'd124;
            7'd6: half_coeff = 16'd178;
            7'd7: half_coeff = 16'd243;
            7'd8: half_coeff = 16'd317;
            7'd9: half_coeff = 16'd401;
            7'd10: half_coeff = 16'd494;
            7'd11: half_coeff = 16'd598;
            7'd12: half_coeff = 16'd710;
            7'd13: half_coeff = 16'd833;
            7'd14: half_coeff = 16'd965;
            7'd15: half_coeff = 16'd1106;
            7'd16: half_coeff = 16'd1256;
            7'd17: half_coeff = 16'd1416;
            7'd18: half_coeff = 16'd1585;
            7'd19: half_coeff = 16'd1762;
            7'd20: half_coeff = 16'd1949;
            7'd21: half_coeff = 16'd2144;
            7'd22: half_coeff = 16'd2348;
            7'd23: half_coeff = 16'd2561;
            7'd24: half_coeff = 16'd2782;
            7'd25: half_coeff = 16'd3011;
            7'd26: half_coeff = 16'd3248;
            7'd27: half_coeff = 16'd3493;
            7'd28: half_coeff = 16'd3746;
            7'd29: half_coeff = 16'd4007;
            7'd30: half_coeff = 16'd4275;
            7'd31: half_coeff = 16'd4551;
            7'd32: half_coeff = 16'd4834;
            7'd33: half_coeff = 16'd5124;
            7'd34: half_coeff = 16'd5420;
            7'd35: half_coeff = 16'd5724;
            7'd36: half_coeff = 16'd6033;
            7'd37: half_coeff = 16'd6349;
            7'd38: half_coeff = 16'd6672;
            7'd39: half_coeff = 16'd7000;
            7'd40: half_coeff = 16'd7333;
            7'd41: half_coeff = 16'd7673;
            7'd42: half_coeff = 16'd8017;
            7'd43: half_coeff = 16'd8367;
            7'd44: half_coeff = 16'd8721;
            7'd45: half_coeff = 16'd9080;
            7'd46: half_coeff = 16'd9444;
            7'd47: half_coeff = 16'd9812;
            7'd48: half_coeff = 16'd10183;
            7'd49: half_coeff = 16'd10559;
            7'd50: half_coeff = 16'd10938;
            7'd51: half_coeff = 16'd11320;
            7'd52: half_coeff = 16'd11706;
            7'd53: half_coeff = 16'd12094;
            7'd54: half_coeff = 16'd12485;
            7'd55: half_coeff = 16'd12878;
            7'd56: half_coeff = 16'd13273;
            7'd57: half_coeff = 16'd13671;
            7'd58: half_coeff = 16'd14070;
            7'd59: half_coeff = 16'd14470;
            7'd60: half_coeff = 16'd14871;
            7'd61: half_coeff = 16'd15274;
            7'd62: half_coeff = 16'd15677;
            7'd63: half_coeff = 16'd16080;
            7'd64: half_coeff = 16'd16484;
            7'd65: half_coeff = 16'd16888;
            7'd66: half_coeff = 16'd17291;
            7'd67: half_coeff = 16'd17694;
            7'd68: half_coeff = 16'd18096;
            7'd69: half_coeff = 16'd18496;
            7'd70: half_coeff = 16'd18896;
            7'd71: half_coeff = 16'd19294;
            7'd72: half_coeff = 16'd19691;
            7'd73: half_coeff = 16'd20085;
            7'd74: half_coeff = 16'd20477;
            7'd75: half_coeff = 16'd20867;
            7'd76: half_coeff = 16'd21253;
            7'd77: half_coeff = 16'd21637;
            7'd78: half_coeff = 16'd22018;
            7'd79: half_coeff = 16'd22395;
            7'd80: half_coeff = 16'd22769;
            7'd81: half_coeff = 16'd23139;
            7'd82: half_coeff = 16'd23505;
            7'd83: half_coeff = 16'd23866;
            7'd84: half_coeff = 16'd24223;
            7'd85: half_coeff = 16'd24575;
            7'd86: half_coeff = 16'd24922;
            7'd87: half_coeff = 16'd25264;
            7'd88: half_coeff = 16'd25600;
            7'd89: half_coeff = 16'd25931;
            7'd90: half_coeff = 16'd26256;
            7'd91: half_coeff = 16'd26575;
            7'd92: half_coeff = 16'd26888;
            7'd93: half_coeff = 16'd27195;
            7'd94: half_coeff = 16'd27495;
            7'd95: half_coeff = 16'd27788;
            7'd96: half_coeff = 16'd28074;
            7'd97: half_coeff = 16'd28354;
            7'd98: half_coeff = 16'd28626;
            7'd99: half_coeff = 16'd28890;
            7'd100: half_coeff = 16'd29147;
            7'd101: half_coeff = 16'd29396;
            7'd102: half_coeff = 16'd29638;
            7'd103: half_coeff = 16'd29871;
            7'd104: half_coeff = 16'd30096;
            7'd105: half_coeff = 16'd30313;
            7'd106: half_coeff = 16'd30521;
            7'd107: half_coeff = 16'd30720;
            7'd108: half_coeff = 16'd30911;
            7'd109: half_coeff = 16'd31094;
            7'd110: half_coeff = 16'd31267;
            7'd111: half_coeff = 16'd31431;
            7'd112: half_coeff = 16'd31586;
            7'd113: half_coeff = 16'd31732;
            7'd114: half_coeff = 16'd31868;
            7'd115: half_coeff = 16'd31996;
            7'd116: half_coeff = 16'd32113;
            7'd117: half_coeff = 16'd32221;
            7'd118: half_coeff = 16'd32320;
            7'd119: half_coeff = 16'd32408;
            7'd120: half_coeff = 16'd32488;
            7'd121: half_coeff = 16'd32557;
            7'd122: half_coeff = 16'd32616;
            7'd123: half_coeff = 16'd32666;
            7'd124: half_coeff = 16'd32706;
            7'd125: half_coeff = 16'd32735;
            7'd126: half_coeff = 16'd32755;
            7'd127: half_coeff = 16'd32765;
            default: half_coeff = 16'd0;
        endcase

        coeff = half_coeff[COEFF_WIDTH-1:0];
    end

endmodule
