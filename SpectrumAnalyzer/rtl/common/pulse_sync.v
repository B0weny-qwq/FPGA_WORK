// 模块名: pulse_sync
// 功能: 在两个无关时钟域之间传递单周期脉冲
// 时钟域: clk_src 到 clk_dst
// 输入: pulse_src
// 输出: pulse_dst
// 说明: 使用“脉冲转翻转位”的 CDC 方法，源脉冲间隔需大于目的域同步延迟

`timescale 1ns / 1ps

module pulse_sync (
    input  wire clk_src,
    input  wire src_rst_n,
    input  wire clk_dst,
    input  wire dst_rst_n,
    input  wire pulse_src,
    output wire pulse_dst
);

    // 源时钟域：把单周期脉冲转换成翻转位。
    reg toggle_src;

    // 目的时钟域：同步翻转位，并用异或恢复成一个目的域脉冲。
    reg [2:0] toggle_dst_sync;

    assign pulse_dst = toggle_dst_sync[2] ^ toggle_dst_sync[1];

    always @(posedge clk_src or negedge src_rst_n) begin
        if (!src_rst_n) begin
            toggle_src <= 1'b0;
        end else if (pulse_src) begin
            toggle_src <= ~toggle_src;
        end
    end

    always @(posedge clk_dst or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            toggle_dst_sync <= 3'b000;
        end else begin
            toggle_dst_sync <= {toggle_dst_sync[1:0], toggle_src};
        end
    end

endmodule
