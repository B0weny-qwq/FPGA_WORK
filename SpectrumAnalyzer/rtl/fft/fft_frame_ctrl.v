// 模块名: fft_frame_ctrl
// 功能: 向 FFT 封装输入精确长度的一帧采样数据
// 时钟域: clk_fft
// 输入: FIFO 读数据和 FFT ready
// 输出: FIFO 读使能和打包后的 AXI-Stream FFT 输入
// 说明: 虚部输入固定为 0，最后一个样本产生 tlast

`timescale 1ns / 1ps

module fft_frame_ctrl #(
    parameter DATA_WIDTH = 16,
    parameter FFT_SIZE   = 256,
    parameter CNT_WIDTH  = 8
) (
    input  wire                         clk_fft,
    input  wire                         fft_rst_n,
    input  wire                         fifo_empty,
    input  wire signed [DATA_WIDTH-1:0] fifo_rd_data,
    input  wire                         fifo_rd_valid,
    input  wire                         fft_in_ready,
    output wire                         fifo_rd_en,
    output reg  [2*DATA_WIDTH-1:0]      fft_s_axis_tdata,
    output reg                          fft_s_axis_tvalid,
    output reg                          fft_s_axis_tlast,
    output reg                          frame_start,
    output reg                          frame_done,
    output reg  [CNT_WIDTH-1:0]         debug_sample_cnt
);

    localparam [CNT_WIDTH-1:0] LAST_SAMPLE = FFT_SIZE - 1;

    reg frame_pause;
    reg ready_low_seen;

    assign fifo_rd_en = fft_in_ready & ~fifo_empty
                      & ~frame_pause
                      & ~(fifo_rd_valid && (debug_sample_cnt == LAST_SAMPLE));

    always @(posedge clk_fft or negedge fft_rst_n) begin
        if (!fft_rst_n) begin
            fft_s_axis_tdata <= {(2*DATA_WIDTH){1'b0}};
            fft_s_axis_tvalid <= 1'b0;
            fft_s_axis_tlast <= 1'b0;
            frame_start <= 1'b0;
            frame_done <= 1'b0;
            debug_sample_cnt <= {CNT_WIDTH{1'b0}};
            frame_pause <= 1'b0;
            ready_low_seen <= 1'b0;
        end else begin
            fft_s_axis_tvalid <= fifo_rd_valid;
            fft_s_axis_tlast <= 1'b0;
            frame_start <= 1'b0;
            frame_done <= 1'b0;

            if (frame_pause) begin
                if (!fft_in_ready) begin
                    ready_low_seen <= 1'b1;
                end else if (ready_low_seen) begin
                    frame_pause <= 1'b0;
                    ready_low_seen <= 1'b0;
                end
            end

            if (fifo_rd_valid) begin
                // FFT 输入打包格式：{imag[15:0], real[15:0]}，本设计虚部为 0。
                fft_s_axis_tdata <= {{DATA_WIDTH{1'b0}}, fifo_rd_data};
                fft_s_axis_tlast <= (debug_sample_cnt == LAST_SAMPLE);
                frame_start <= (debug_sample_cnt == {CNT_WIDTH{1'b0}});
                frame_done <= (debug_sample_cnt == LAST_SAMPLE);

                if (debug_sample_cnt == LAST_SAMPLE) begin
                    debug_sample_cnt <= {CNT_WIDTH{1'b0}};
                    frame_pause <= 1'b1;
                    ready_low_seen <= 1'b0;
                end else begin
                    debug_sample_cnt <= debug_sample_cnt + {{(CNT_WIDTH-1){1'b0}}, 1'b1};
                end
            end
        end
    end

endmodule
