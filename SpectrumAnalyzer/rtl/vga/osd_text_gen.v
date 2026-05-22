// 模块名: osd_text_gen
// 功能: 在频谱画面上绘制固定状态文字
// 时钟域: clk_pixel
// 输入: VGA 坐标和状态值
// 输出: OSD RGB 图层和有效标志
// 说明: 文字内容由波形、FFT 点数、峰值频点和窗口状态组成

`timescale 1ns / 1ps

module osd_text_gen #(
    parameter TEXT_COLS = 32
) (
    input  wire        clk_pixel,
    input  wire        pixel_rst_n,
    input  wire        active_video,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire [1:0]  wave_sel,
    input  wire        window_en,
    input  wire [7:0]  peak_bin,
    output reg  [11:0] osd_rgb,
    output reg         osd_on
);

    localparam TEXT_X0 = 10'd24;
    localparam TEXT_Y0 = 10'd24;
    localparam CHAR_W  = 10'd8;
    localparam CHAR_H  = 10'd16;

    wire text_area;
    wire [5:0] char_col;
    wire [9:0] text_x;
    wire [9:0] text_y;
    wire [3:0] char_row;
    wire [2:0] bit_col;
    wire [7:0] font_bits;
    wire       font_pixel;

    reg [7:0] char_code;
    reg [7:0] wave_char;
    reg [3:0] peak_hundreds;
    reg [3:0] peak_tens;
    reg [3:0] peak_ones;
    integer peak_value;

    assign text_area = active_video
                    && (pixel_x >= TEXT_X0)
                    && (pixel_x < (TEXT_X0 + TEXT_COLS * CHAR_W))
                    && (pixel_y >= TEXT_Y0)
                    && (pixel_y < (TEXT_Y0 + CHAR_H));
    assign text_x = pixel_x - TEXT_X0;
    assign text_y = pixel_y - TEXT_Y0;
    assign char_col = text_x >> 3;
    assign char_row = text_y[3:0];
    assign bit_col = 3'd7 - text_x[2:0];
    assign font_pixel = text_area && font_bits[bit_col];

    font_rom_8x16 u_font_rom_8x16 (
        .ascii_code (char_code),
        .row_idx    (char_row),
        .row_bits   (font_bits)
    );

    // 固定 OSD 字符串：WAVE:x FFT:256 PEAK:nnn WIN:x。
    always @(*) begin
        case (wave_sel)
            2'd0: wave_char = "S";
            2'd1: wave_char = "Q";
            2'd2: wave_char = "T";
            default: wave_char = "W";
        endcase

        peak_value = peak_bin;
        peak_hundreds = peak_value / 100;
        peak_tens = (peak_value % 100) / 10;
        peak_ones = peak_value % 10;

        char_code = " ";

        case (char_col)
            6'd0:  char_code = "W";
            6'd1:  char_code = "A";
            6'd2:  char_code = "V";
            6'd3:  char_code = "E";
            6'd4:  char_code = ":";
            6'd5:  char_code = wave_char;
            6'd7:  char_code = "F";
            6'd8:  char_code = "F";
            6'd9:  char_code = "T";
            6'd10: char_code = ":";
            6'd11: char_code = "2";
            6'd12: char_code = "5";
            6'd13: char_code = "6";
            6'd15: char_code = "P";
            6'd16: char_code = "E";
            6'd17: char_code = "A";
            6'd18: char_code = "K";
            6'd19: char_code = ":";
            6'd20: char_code = "0" + peak_hundreds;
            6'd21: char_code = "0" + peak_tens;
            6'd22: char_code = "0" + peak_ones;
            6'd24: char_code = "W";
            6'd25: char_code = "I";
            6'd26: char_code = "N";
            6'd27: char_code = ":";
            6'd28: char_code = window_en ? "1" : "0";
            default: char_code = " ";
        endcase
    end

    always @(posedge clk_pixel or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin
            osd_rgb <= 12'h000;
            osd_on <= 1'b0;
        end else begin
            osd_on <= font_pixel;
            osd_rgb <= font_pixel ? 12'hFF6 : 12'h000;
        end
    end

endmodule
