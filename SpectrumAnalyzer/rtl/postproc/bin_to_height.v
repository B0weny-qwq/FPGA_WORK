// 模块名: bin_to_height
// 功能: 将压缩显示等级转换成 VGA 柱状图高度
// 时钟域: VGA 组合数据通路
// 输入: 压缩等级
// 输出: 限幅后的像素高度
// 说明: 满量程输入对应 MAX_HEIGHT 高度

`timescale 1ns / 1ps

module bin_to_height #(
    parameter LEVEL_WIDTH  = 8,
    parameter HEIGHT_WIDTH = 9,
    parameter MAX_HEIGHT   = 220
) (
    input  wire [LEVEL_WIDTH-1:0]   level_data,
    output reg  [HEIGHT_WIDTH-1:0]  bar_height
);

    localparam [HEIGHT_WIDTH-1:0] MAX_HEIGHT_CLAMP = MAX_HEIGHT;

    reg [HEIGHT_WIDTH+LEVEL_WIDTH-1:0] scaled_height;

    always @(*) begin
        scaled_height = level_data * MAX_HEIGHT;
        bar_height = scaled_height >> LEVEL_WIDTH;

        if (bar_height > MAX_HEIGHT_CLAMP) begin
            bar_height = MAX_HEIGHT_CLAMP;
        end
    end

endmodule
