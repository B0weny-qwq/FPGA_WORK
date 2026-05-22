// 模块名: fft_mag_calc
// 功能: 将复数 FFT 输出转换成功率幅度
// 时钟域: clk_fft
// 输入: 打包后的 FFT 输出流
// 输出: 幅度、频点编号和帧结束标志
// 说明: tdata 格式为 {imag[15:0], real[15:0]}

`timescale 1ns / 1ps

module fft_mag_calc #(
    parameter DATA_WIDTH = 16,
    parameter MAG_WIDTH  = 32,
    parameter BIN_WIDTH  = 8,
    parameter FFT_SIZE   = 256
) (
    input  wire                    clk_fft,
    input  wire                    fft_rst_n,
    input  wire [2*DATA_WIDTH-1:0] fft_tdata,
    input  wire                    fft_tvalid,
    input  wire                    fft_tlast,
    output reg  [MAG_WIDTH-1:0]    mag_data,
    output reg  [BIN_WIDTH-1:0]    mag_bin,
    output reg                     mag_valid,
    output reg                     mag_frame_done
);

    localparam [BIN_WIDTH-1:0] LAST_BIN = FFT_SIZE - 1;

    wire signed [DATA_WIDTH-1:0] fft_re;
    wire signed [DATA_WIDTH-1:0] fft_im;
    wire [2*DATA_WIDTH-1:0] re_square;
    wire [2*DATA_WIDTH-1:0] im_square;
    wire [MAG_WIDTH-1:0] mag_sum;

    reg [BIN_WIDTH-1:0] bin_cnt;

    assign fft_re = fft_tdata[DATA_WIDTH-1:0];
    assign fft_im = fft_tdata[2*DATA_WIDTH-1:DATA_WIDTH];
    assign re_square = $unsigned(fft_re * fft_re);
    assign im_square = $unsigned(fft_im * fft_im);
    assign mag_sum = re_square + im_square;

    always @(posedge clk_fft or negedge fft_rst_n) begin
        if (!fft_rst_n) begin
            mag_data <= {MAG_WIDTH{1'b0}};
            mag_bin <= {BIN_WIDTH{1'b0}};
            mag_valid <= 1'b0;
            mag_frame_done <= 1'b0;
            bin_cnt <= {BIN_WIDTH{1'b0}};
        end else begin
            mag_valid <= fft_tvalid;
            mag_frame_done <= 1'b0;

            if (fft_tvalid) begin
                mag_data <= mag_sum;
                mag_bin <= bin_cnt;
                mag_frame_done <= fft_tlast;

                if (fft_tlast || (bin_cnt == LAST_BIN)) begin
                    bin_cnt <= {BIN_WIDTH{1'b0}};
                end else begin
                    bin_cnt <= bin_cnt + {{(BIN_WIDTH-1){1'b0}}, 1'b1};
                end
            end
        end
    end

endmodule
