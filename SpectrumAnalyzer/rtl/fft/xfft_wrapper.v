// 模块名: xfft_wrapper
// 功能: 隔离 Vivado FFT IP 与工程其他 RTL 的接口
// 时钟域: clk_fft
// 输入: AXI-Stream 时域采样数据
// 输出: AXI-Stream 复数频域数据
// 说明: 仿真使用行为级 DFT；综合使用接口占位通路，真实上板时替换为 Vivado FFT IP

`timescale 1ns / 1ps

module xfft_wrapper #(
    parameter DATA_WIDTH = 16,
    parameter FFT_SIZE   = 256,
    parameter BIN_WIDTH  = 8
) (
    input  wire                    clk_fft,
    input  wire                    fft_rst_n,
    input  wire [2*DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                    s_axis_tvalid,
    input  wire                    s_axis_tlast,
    output wire                    s_axis_tready,
    output reg  [2*DATA_WIDTH-1:0] m_axis_tdata,
    output reg                     m_axis_tvalid,
    output reg                     m_axis_tlast,
    input  wire                    m_axis_tready,
    output reg                     event_tlast_missing,
    output reg                     event_tlast_unexpected,
    output reg  [BIN_WIDTH-1:0]    debug_out_bin
);

`ifdef XFFT_BEHAVIORAL_DFT_SIM

    localparam STATE_INPUT  = 2'd0;
    localparam STATE_CALC   = 2'd1;
    localparam STATE_OUTPUT = 2'd2;

    localparam signed [DATA_WIDTH-1:0] ZERO_SAMPLE = {DATA_WIDTH{1'b0}};
    localparam [BIN_WIDTH-1:0] LAST_BIN = FFT_SIZE - 1;
    localparam DFT_OUTPUT_SHIFT = 16;

    reg [1:0] state_cur;
    reg [BIN_WIDTH-1:0] input_cnt;
    reg [BIN_WIDTH-1:0] calc_bin;
    reg [BIN_WIDTH-1:0] calc_idx;
    reg [BIN_WIDTH-1:0] output_cnt;
    reg signed [DATA_WIDTH-1:0] sample_mem [0:FFT_SIZE-1];
    reg signed [47:0] acc_re;
    reg signed [47:0] acc_im;
    reg signed [DATA_WIDTH-1:0] re_mem [0:FFT_SIZE-1];
    reg signed [DATA_WIDTH-1:0] im_mem [0:FFT_SIZE-1];
    reg signed [47:0] dft_term_re;
    reg signed [47:0] dft_term_im;

    real angle;
    real scale_re;
    real scale_im;
    integer init_idx;

    assign s_axis_tready = (state_cur == STATE_INPUT);

    initial begin
        for (init_idx = 0; init_idx < FFT_SIZE; init_idx = init_idx + 1) begin
            sample_mem[init_idx] = ZERO_SAMPLE;
            re_mem[init_idx] = ZERO_SAMPLE;
            im_mem[init_idx] = ZERO_SAMPLE;
        end
    end

    // 行为级 DFT 当前项计算：只用于仿真，方便验证峰值频点是否正确。
    always @(*) begin
        angle = -6.28318530717958647692 * calc_bin * calc_idx / FFT_SIZE;
        scale_re = $cos(angle) * 256.0;
        scale_im = $sin(angle) * 256.0;
        dft_term_re = $signed(sample_mem[calc_idx]) * $rtoi(scale_re);
        dft_term_im = $signed(sample_mem[calc_idx]) * $rtoi(scale_im);
    end

    always @(posedge clk_fft or negedge fft_rst_n) begin
        if (!fft_rst_n) begin
            state_cur <= STATE_INPUT;
            input_cnt <= {BIN_WIDTH{1'b0}};
            calc_bin <= {BIN_WIDTH{1'b0}};
            calc_idx <= {BIN_WIDTH{1'b0}};
            output_cnt <= {BIN_WIDTH{1'b0}};
            acc_re <= 48'sd0;
            acc_im <= 48'sd0;
            m_axis_tdata <= {(2*DATA_WIDTH){1'b0}};
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            event_tlast_missing <= 1'b0;
            event_tlast_unexpected <= 1'b0;
            debug_out_bin <= {BIN_WIDTH{1'b0}};
        end else begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;

            case (state_cur)
                STATE_INPUT: begin
                    if (s_axis_tvalid) begin
                        sample_mem[input_cnt] <= s_axis_tdata[DATA_WIDTH-1:0];

                        if ((input_cnt == LAST_BIN) && !s_axis_tlast) begin
                            event_tlast_missing <= 1'b1;
                        end

                        if ((input_cnt != LAST_BIN) && s_axis_tlast) begin
                            event_tlast_unexpected <= 1'b1;
                        end

                        if (input_cnt == LAST_BIN) begin
                            input_cnt <= {BIN_WIDTH{1'b0}};
                            calc_bin <= {BIN_WIDTH{1'b0}};
                            calc_idx <= {BIN_WIDTH{1'b0}};
                            acc_re <= 48'sd0;
                            acc_im <= 48'sd0;
                            state_cur <= STATE_CALC;
                        end else begin
                            input_cnt <= input_cnt + {{(BIN_WIDTH-1){1'b0}}, 1'b1};
                        end
                    end
                end

                STATE_CALC: begin
                    if (calc_idx == LAST_BIN) begin
                        re_mem[calc_bin] <= (acc_re + dft_term_re) >>> DFT_OUTPUT_SHIFT;
                        im_mem[calc_bin] <= (acc_im + dft_term_im) >>> DFT_OUTPUT_SHIFT;
                        acc_re <= 48'sd0;
                        acc_im <= 48'sd0;
                        calc_idx <= {BIN_WIDTH{1'b0}};

                        if (calc_bin == LAST_BIN) begin
                            output_cnt <= {BIN_WIDTH{1'b0}};
                            state_cur <= STATE_OUTPUT;
                        end else begin
                            calc_bin <= calc_bin + {{(BIN_WIDTH-1){1'b0}}, 1'b1};
                        end
                    end else begin
                        acc_re <= acc_re + dft_term_re;
                        acc_im <= acc_im + dft_term_im;
                        calc_idx <= calc_idx + {{(BIN_WIDTH-1){1'b0}}, 1'b1};
                    end
                end

                STATE_OUTPUT: begin
                    if (m_axis_tready) begin
                        // FFT 输出打包格式：{imag[15:0], real[15:0]}。
                        m_axis_tdata <= {im_mem[output_cnt], re_mem[output_cnt]};
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast <= (output_cnt == LAST_BIN);
                        debug_out_bin <= output_cnt;

                        if (output_cnt == LAST_BIN) begin
                            output_cnt <= {BIN_WIDTH{1'b0}};
                            state_cur <= STATE_INPUT;
                        end else begin
                            output_cnt <= output_cnt + {{(BIN_WIDTH-1){1'b0}}, 1'b1};
                        end
                    end
                end

                default: begin
                    state_cur <= STATE_INPUT;
                end
            endcase
        end
    end

`else

    localparam [BIN_WIDTH-1:0] LAST_BIN = FFT_SIZE - 1;

    reg [BIN_WIDTH-1:0] input_cnt;
    reg                 output_busy;

    assign s_axis_tready = !output_busy;

    always @(posedge clk_fft or negedge fft_rst_n) begin
        if (!fft_rst_n) begin
            input_cnt <= {BIN_WIDTH{1'b0}};
            output_busy <= 1'b0;
            m_axis_tdata <= {(2*DATA_WIDTH){1'b0}};
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            event_tlast_missing <= 1'b0;
            event_tlast_unexpected <= 1'b0;
            debug_out_bin <= {BIN_WIDTH{1'b0}};
        end else begin
            if (m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                output_busy <= 1'b0;
            end

            if (s_axis_tvalid && s_axis_tready) begin
                // 可综合占位：保持 AXI-Stream 握手和帧边界，不执行真实 FFT。
                m_axis_tdata <= s_axis_tdata;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= s_axis_tlast;
                output_busy <= 1'b1;
                debug_out_bin <= input_cnt;

                if ((input_cnt == LAST_BIN) && !s_axis_tlast) begin
                    event_tlast_missing <= 1'b1;
                end

                if ((input_cnt != LAST_BIN) && s_axis_tlast) begin
                    event_tlast_unexpected <= 1'b1;
                end

                if ((input_cnt == LAST_BIN) || s_axis_tlast) begin
                    input_cnt <= {BIN_WIDTH{1'b0}};
                end else begin
                    input_cnt <= input_cnt + {{(BIN_WIDTH-1){1'b0}}, 1'b1};
                end
            end
        end
    end

`endif

endmodule
