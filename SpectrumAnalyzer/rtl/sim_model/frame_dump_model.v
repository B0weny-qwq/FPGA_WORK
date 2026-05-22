// 模块名: frame_dump_model
// 功能: 将一帧 VGA RGB 像素导出为文本，便于离线检查
// 时钟域: clk_pixel
// 输入: VGA 时序和 RGB 像素流
// 输出: frame_done 脉冲
// 说明: 仅用于仿真；DUMP_ENABLE 非零时写出文本文件

`timescale 1ns / 1ps

module frame_dump_model #(
    parameter DUMP_ENABLE = 0,
    parameter FILE_NAME   = "sim/data/vga_frame_dump.txt"
) (
    input  wire       clk_pixel,
    input  wire       pixel_rst_n,
    input  wire       active_video,
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire [3:0] vga_r,
    input  wire [3:0] vga_g,
    input  wire [3:0] vga_b,
    output reg        frame_done
);

    integer file_handle;
    reg dumped_once;

    initial begin
        if (DUMP_ENABLE != 0) begin
            file_handle = $fopen(FILE_NAME, "w");
        end else begin
            file_handle = 0;
        end
    end

    always @(posedge clk_pixel or negedge pixel_rst_n) begin
        if (!pixel_rst_n) begin
            frame_done <= 1'b0;
            dumped_once <= 1'b0;
        end else begin
            frame_done <= 1'b0;

            if ((DUMP_ENABLE != 0) && !dumped_once && active_video) begin
                $fwrite(file_handle, "%0d,%0d,%h%h%h\n", pixel_x, pixel_y, vga_r, vga_g, vga_b);
            end

            if (!dumped_once && (pixel_x == 10'd639) && (pixel_y == 10'd479)) begin
                dumped_once <= 1'b1;
                frame_done <= 1'b1;

                if (DUMP_ENABLE != 0) begin
                    $fflush(file_handle);
                end
            end
        end
    end

endmodule
