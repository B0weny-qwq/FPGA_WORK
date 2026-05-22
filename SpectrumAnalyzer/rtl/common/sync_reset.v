// 模块名: sync_reset
// 功能: 将外部低有效复位同步到目标时钟域
// 时钟域: 目标 clk
// 输入: ext_rst_n
// 输出: rst_n
// 说明: 复位异步拉低，同步释放，避免复位释放时产生亚稳态风险

`timescale 1ns / 1ps

module sync_reset #(
    parameter STAGES = 3
) (
    input  wire clk,
    input  wire ext_rst_n,
    output wire rst_n
);

    // 复位同步移位寄存器，连续移入 1 后才释放目标域复位。
    reg [STAGES-1:0] rst_shift;

    assign rst_n = rst_shift[STAGES-1];

    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            rst_shift <= {STAGES{1'b0}};
        end else begin
            rst_shift <= {rst_shift[STAGES-2:0], 1'b1};
        end
    end

endmodule
