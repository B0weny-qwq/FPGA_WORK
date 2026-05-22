// 模块名: clk_rst_gen
// 功能: 为样本域、FFT 域和像素域分别产生同步复位
// 时钟域: clk_sample, clk_fft, clk_pixel
// 输入: rst_n
// 输出: sample_rst_n, fft_rst_n, pixel_rst_n
// 说明: 本模块不产生时钟，只负责把外部复位分发到各时钟域

`timescale 1ns / 1ps

module clk_rst_gen (
    input  wire clk_sample,
    input  wire clk_fft,
    input  wire clk_pixel,
    input  wire rst_n,
    output wire sample_rst_n,
    output wire fft_rst_n,
    output wire pixel_rst_n
);

    sync_reset u_sync_reset_sample (
        .clk       (clk_sample),
        .ext_rst_n (rst_n),
        .rst_n     (sample_rst_n)
    );

    sync_reset u_sync_reset_fft (
        .clk       (clk_fft),
        .ext_rst_n (rst_n),
        .rst_n     (fft_rst_n)
    );

    sync_reset u_sync_reset_pixel (
        .clk       (clk_pixel),
        .ext_rst_n (rst_n),
        .rst_n     (pixel_rst_n)
    );

endmodule
