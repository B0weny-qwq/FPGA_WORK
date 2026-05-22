// 模块名: win_mul_optional
// 功能: 可选 Hann 窗乘法器
// 时钟域: clk_sample
// 输入: 有符号样本流、窗口使能
// 输出: 加窗后或旁路后的有符号样本流
// 说明: Q1.15 系数乘法后右移 15 位恢复样本位宽

`timescale 1ns / 1ps

module win_mul_optional #(
    parameter DATA_WIDTH  = 16,
    parameter ADDR_WIDTH  = 8,
    parameter COEFF_WIDTH = 16
) (
    input  wire                         clk_sample,
    input  wire                         sample_rst_n,
    input  wire                         window_en,
    input  wire signed [DATA_WIDTH-1:0] sample_in,
    input  wire                         sample_in_valid,
    output reg  signed [DATA_WIDTH-1:0] sample_out,
    output reg                          sample_out_valid,
    output reg  [ADDR_WIDTH-1:0]        debug_coeff_addr
);

    wire [COEFF_WIDTH-1:0] coeff;
    wire signed [DATA_WIDTH+COEFF_WIDTH:0] product;

    hann_rom #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .COEFF_WIDTH (COEFF_WIDTH)
    ) u_hann_rom (
        .addr  (debug_coeff_addr),
        .coeff (coeff)
    );

    // 定点乘法说明：系数始终为正数，前面补 0 后再参与有符号乘法。
    assign product = $signed(sample_in) * $signed({1'b0, coeff});

    always @(posedge clk_sample or negedge sample_rst_n) begin
        if (!sample_rst_n) begin
            sample_out       <= {DATA_WIDTH{1'b0}};
            sample_out_valid <= 1'b0;
            debug_coeff_addr <= {ADDR_WIDTH{1'b0}};
        end else begin
            sample_out_valid <= sample_in_valid;

            if (sample_in_valid) begin
                if (window_en) begin
                    sample_out <= product >>> (COEFF_WIDTH - 1);
                end else begin
                    sample_out <= sample_in;
                end

                debug_coeff_addr <= debug_coeff_addr + {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
            end
        end
    end

endmodule
