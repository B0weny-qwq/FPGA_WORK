// 模块名: font_rom_8x16
// 功能: OSD 文字使用的简化 8x16 字库
// 时钟域: 组合文字数据通路
// 输入: ASCII 编码和字符行号
// 输出: 8 像素字符行
// 说明: 包含数字、常用大写字母、冒号、空格和等号

`timescale 1ns / 1ps

module font_rom_8x16 (
    input  wire [7:0] ascii_code,
    input  wire [3:0] row_idx,
    output reg  [7:0] row_bits
);

    reg [6:0] font_idx;
    reg [7:0] glyph_8x8;

    always @(*) begin
        case (ascii_code)
            "0": font_idx = 7'd0;
            "1": font_idx = 7'd1;
            "2": font_idx = 7'd2;
            "3": font_idx = 7'd3;
            "4": font_idx = 7'd4;
            "5": font_idx = 7'd5;
            "6": font_idx = 7'd6;
            "7": font_idx = 7'd7;
            "8": font_idx = 7'd8;
            "9": font_idx = 7'd9;
            "A": font_idx = 7'd10;
            "B": font_idx = 7'd11;
            "C": font_idx = 7'd12;
            "D": font_idx = 7'd13;
            "E": font_idx = 7'd14;
            "F": font_idx = 7'd15;
            "G": font_idx = 7'd16;
            "H": font_idx = 7'd17;
            "I": font_idx = 7'd18;
            "K": font_idx = 7'd19;
            "L": font_idx = 7'd20;
            "M": font_idx = 7'd21;
            "N": font_idx = 7'd22;
            "O": font_idx = 7'd23;
            "P": font_idx = 7'd24;
            "Q": font_idx = 7'd25;
            "R": font_idx = 7'd26;
            "S": font_idx = 7'd27;
            "T": font_idx = 7'd28;
            "V": font_idx = 7'd29;
            "W": font_idx = 7'd30;
            "X": font_idx = 7'd31;
            "Y": font_idx = 7'd32;
            ":": font_idx = 7'd33;
            "=": font_idx = 7'd34;
            default: font_idx = 7'd35;
        endcase
    end

    always @(*) begin
        glyph_8x8 = 8'b00000000;

        case (font_idx)
            7'd0: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b00111100;
                    3'd1: glyph_8x8 = 8'b01100110;
                    3'd2: glyph_8x8 = 8'b01101110;
                    3'd3: glyph_8x8 = 8'b01110110;
                    3'd4: glyph_8x8 = 8'b01100110;
                    3'd5: glyph_8x8 = 8'b01100110;
                    3'd6: glyph_8x8 = 8'b00111100;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd1: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b00011000;
                    3'd1: glyph_8x8 = 8'b00111000;
                    3'd2: glyph_8x8 = 8'b00011000;
                    3'd3: glyph_8x8 = 8'b00011000;
                    3'd4: glyph_8x8 = 8'b00011000;
                    3'd5: glyph_8x8 = 8'b00011000;
                    3'd6: glyph_8x8 = 8'b01111110;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd2: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b00111100;
                    3'd1: glyph_8x8 = 8'b01100110;
                    3'd2: glyph_8x8 = 8'b00000110;
                    3'd3: glyph_8x8 = 8'b00011100;
                    3'd4: glyph_8x8 = 8'b00110000;
                    3'd5: glyph_8x8 = 8'b01100000;
                    3'd6: glyph_8x8 = 8'b01111110;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd3: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b00111100;
                    3'd1: glyph_8x8 = 8'b01100110;
                    3'd2: glyph_8x8 = 8'b00000110;
                    3'd3: glyph_8x8 = 8'b00011100;
                    3'd4: glyph_8x8 = 8'b00000110;
                    3'd5: glyph_8x8 = 8'b01100110;
                    3'd6: glyph_8x8 = 8'b00111100;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd4: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b00001100;
                    3'd1: glyph_8x8 = 8'b00011100;
                    3'd2: glyph_8x8 = 8'b00101100;
                    3'd3: glyph_8x8 = 8'b01001100;
                    3'd4: glyph_8x8 = 8'b01111110;
                    3'd5: glyph_8x8 = 8'b00001100;
                    3'd6: glyph_8x8 = 8'b00001100;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd5: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b01111110;
                    3'd1: glyph_8x8 = 8'b01100000;
                    3'd2: glyph_8x8 = 8'b01111100;
                    3'd3: glyph_8x8 = 8'b00000110;
                    3'd4: glyph_8x8 = 8'b00000110;
                    3'd5: glyph_8x8 = 8'b01100110;
                    3'd6: glyph_8x8 = 8'b00111100;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd6: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b00111100;
                    3'd1: glyph_8x8 = 8'b01100000;
                    3'd2: glyph_8x8 = 8'b01111100;
                    3'd3: glyph_8x8 = 8'b01100110;
                    3'd4: glyph_8x8 = 8'b01100110;
                    3'd5: glyph_8x8 = 8'b01100110;
                    3'd6: glyph_8x8 = 8'b00111100;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd7: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b01111110;
                    3'd1: glyph_8x8 = 8'b00000110;
                    3'd2: glyph_8x8 = 8'b00001100;
                    3'd3: glyph_8x8 = 8'b00011000;
                    3'd4: glyph_8x8 = 8'b00110000;
                    3'd5: glyph_8x8 = 8'b00110000;
                    3'd6: glyph_8x8 = 8'b00110000;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd8: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b00111100;
                    3'd1: glyph_8x8 = 8'b01100110;
                    3'd2: glyph_8x8 = 8'b01100110;
                    3'd3: glyph_8x8 = 8'b00111100;
                    3'd4: glyph_8x8 = 8'b01100110;
                    3'd5: glyph_8x8 = 8'b01100110;
                    3'd6: glyph_8x8 = 8'b00111100;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd9: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b00111100;
                    3'd1: glyph_8x8 = 8'b01100110;
                    3'd2: glyph_8x8 = 8'b01100110;
                    3'd3: glyph_8x8 = 8'b00111110;
                    3'd4: glyph_8x8 = 8'b00000110;
                    3'd5: glyph_8x8 = 8'b00001100;
                    3'd6: glyph_8x8 = 8'b00111000;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd10: begin
                case (row_idx[3:1])
                    3'd0: glyph_8x8 = 8'b00011000;
                    3'd1: glyph_8x8 = 8'b00111100;
                    3'd2: glyph_8x8 = 8'b01100110;
                    3'd3: glyph_8x8 = 8'b01100110;
                    3'd4: glyph_8x8 = 8'b01111110;
                    3'd5: glyph_8x8 = 8'b01100110;
                    3'd6: glyph_8x8 = 8'b01100110;
                    default: glyph_8x8 = 8'b00000000;
                endcase
            end
            7'd11: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd3
                              || row_idx[3:1] == 3'd6) ? 8'b01111100 : 8'b01100110;
            7'd12: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd6)
                              ? 8'b00111100 : 8'b01100000;
            7'd13: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd6)
                              ? 8'b01111000 : 8'b01101100;
            7'd14: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd3
                              || row_idx[3:1] == 3'd6) ? 8'b01111110 : 8'b01100000;
            7'd15: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd3)
                              ? 8'b01111110 : 8'b01100000;
            7'd16: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd6)
                              ? 8'b00111100 : ((row_idx[3:1] >= 3'd3)
                              ? 8'b01100110 : 8'b01100000);
            7'd17: glyph_8x8 = (row_idx[3:1] == 3'd3) ? 8'b01111110 : 8'b01100110;
            7'd18: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd6)
                              ? 8'b01111110 : 8'b00011000;
            7'd19: glyph_8x8 = (row_idx[3:1] < 3'd3) ? 8'b01101100
                              : ((row_idx[3:1] == 3'd3) ? 8'b01111000 : 8'b01101100);
            7'd20: glyph_8x8 = (row_idx[3:1] == 3'd6) ? 8'b01111110 : 8'b01100000;
            7'd21: glyph_8x8 = (row_idx[3:1] == 3'd1) ? 8'b01111110
                              : ((row_idx[3:1] == 3'd2) ? 8'b01111110 : 8'b01100110);
            7'd22: glyph_8x8 = (row_idx[3:1] == 3'd1) ? 8'b01110110
                              : ((row_idx[3:1] == 3'd2) ? 8'b01111110 : 8'b01100110);
            7'd23: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd6)
                              ? 8'b00111100 : 8'b01100110;
            7'd24: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd3)
                              ? 8'b01111100 : 8'b01100110;
            7'd25: glyph_8x8 = (row_idx[3:1] == 3'd0) ? 8'b00111100
                              : ((row_idx[3:1] == 3'd6) ? 8'b00111110 : 8'b01100110);
            7'd26: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd3)
                              ? 8'b01111100 : ((row_idx[3:1] > 3'd3) ? 8'b01101100 : 8'b01100110);
            7'd27: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd3
                              || row_idx[3:1] == 3'd6) ? 8'b00111100
                              : ((row_idx[3:1] < 3'd3) ? 8'b01100000 : 8'b00000110);
            7'd28: glyph_8x8 = (row_idx[3:1] == 3'd0) ? 8'b01111110 : 8'b00011000;
            7'd29: glyph_8x8 = (row_idx[3:1] < 3'd5) ? 8'b01100110
                              : ((row_idx[3:1] == 3'd5) ? 8'b00111100 : 8'b00011000);
            7'd30: glyph_8x8 = (row_idx[3:1] == 3'd4) ? 8'b01111110 : 8'b01100110;
            7'd31: glyph_8x8 = (row_idx[3:1] == 3'd0 || row_idx[3:1] == 3'd6)
                              ? 8'b01100110 : ((row_idx[3:1] == 3'd3) ? 8'b00011000 : 8'b00111100);
            7'd32: glyph_8x8 = (row_idx[3:1] < 3'd3) ? 8'b01100110 : 8'b00011000;
            7'd33: glyph_8x8 = (row_idx[3:1] == 3'd2 || row_idx[3:1] == 3'd4)
                              ? 8'b00011000 : 8'b00000000;
            7'd34: glyph_8x8 = (row_idx[3:1] == 3'd2 || row_idx[3:1] == 3'd4)
                              ? 8'b01111110 : 8'b00000000;
            default: glyph_8x8 = 8'b00000000;
        endcase

        row_bits = glyph_8x8;
    end

endmodule
