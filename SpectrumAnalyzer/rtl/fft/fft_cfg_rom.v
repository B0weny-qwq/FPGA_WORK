// 模块名: fft_cfg_rom
// 功能: 提供固定 FFT 配置字
// 时钟域: 组合配置路径
// 输入: 无
// 输出: AXI-Stream 配置字和有效标志
// 说明: 保留该模块便于后续替换成真实 Vivado FFT IP 配置接口

`timescale 1ns / 1ps

module fft_cfg_rom #(
    parameter CFG_WIDTH = 16
) (
    output wire [CFG_WIDTH-1:0] cfg_data,
    output wire                 cfg_valid
);

    // Vivado xfft 常用约定：bit0 为 1 表示正向 FFT。
    assign cfg_data  = {{(CFG_WIDTH-1){1'b0}}, 1'b1};
    assign cfg_valid = 1'b1;

endmodule
