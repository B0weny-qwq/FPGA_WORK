// 模块名: peak_detector
// 功能: 每帧检测一次主频峰值
// 时钟域: clk_fft
// 输入: 原始幅度流
// 输出: 锁存后的峰值频点和峰值幅度
// 说明: 忽略直流频点，便于单音测试时观察主峰

`timescale 1ns / 1ps

module peak_detector #(
    parameter MAG_WIDTH = 32,
    parameter BIN_WIDTH = 8
) (
    input  wire                 clk_fft,
    input  wire                 fft_rst_n,
    input  wire [MAG_WIDTH-1:0] mag_data,
    input  wire [BIN_WIDTH-1:0] mag_bin,
    input  wire                 mag_valid,
    input  wire                 mag_frame_done,
    output reg  [BIN_WIDTH-1:0] peak_bin,
    output reg  [MAG_WIDTH-1:0] peak_mag,
    output reg                  peak_valid
);

    reg [BIN_WIDTH-1:0] frame_peak_bin;
    reg [MAG_WIDTH-1:0] frame_peak_mag;

    always @(posedge clk_fft or negedge fft_rst_n) begin
        if (!fft_rst_n) begin
            frame_peak_bin <= {BIN_WIDTH{1'b0}};
            frame_peak_mag <= {MAG_WIDTH{1'b0}};
            peak_bin <= {BIN_WIDTH{1'b0}};
            peak_mag <= {MAG_WIDTH{1'b0}};
            peak_valid <= 1'b0;
        end else begin
            peak_valid <= 1'b0;

            if (mag_valid) begin
                if (mag_bin == {BIN_WIDTH{1'b0}}) begin
                    frame_peak_bin <= {BIN_WIDTH{1'b0}};
                    frame_peak_mag <= {MAG_WIDTH{1'b0}};
                end else if (mag_data > frame_peak_mag) begin
                    frame_peak_bin <= mag_bin;
                    frame_peak_mag <= mag_data;
                end

                if (mag_frame_done) begin
                    if ((mag_bin != {BIN_WIDTH{1'b0}}) && (mag_data > frame_peak_mag)) begin
                        peak_bin <= mag_bin;
                        peak_mag <= mag_data;
                    end else begin
                        peak_bin <= frame_peak_bin;
                        peak_mag <= frame_peak_mag;
                    end

                    peak_valid <= 1'b1;
                end
            end
        end
    end

endmodule
