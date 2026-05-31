// 模块名: async_fifo_bridge
// 功能: 异步 FIFO 课程 RTL 与 Vivado FIFO IP 的桥接层
// 时钟域: clk_wr 和 clk_rd
// 输入: 简单写/读请求
// 输出: full、empty、注册读数据和 rd_valid
// 说明: 默认实例化手写 async_fifo；定义 USE_ASYNC_SAMPLE_FIFO_IP 时接入 async_sample_fifo_ip

`timescale 1ns / 1ps

module async_fifo_bridge #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 9
) (
    input  wire                         clk_wr,
    input  wire                         wr_rst_n,
    input  wire                         clk_rd,
    input  wire                         rd_rst_n,
    input  wire                         wr_en,
    input  wire signed [DATA_WIDTH-1:0] wr_data,
    input  wire                         rd_en,
    output wire signed [DATA_WIDTH-1:0] rd_data,
    output wire                         rd_valid,
    output wire                         full,
    output wire                         empty,
    output wire [ADDR_WIDTH:0]          debug_wr_level,
    output wire [ADDR_WIDTH:0]          debug_rd_level
);

`ifdef USE_ASYNC_SAMPLE_FIFO_IP

    wire wr_rst_busy;
    wire rd_rst_busy;

    // 可选 IP 路径用于综合电路图展示。默认仿真和课程讲解仍使用手写 FIFO。
    async_sample_fifo_ip u_async_sample_fifo_ip (
        .rst         (~(wr_rst_n & rd_rst_n)),
        .wr_clk      (clk_wr),
        .rd_clk      (clk_rd),
        .din         (wr_data),
        .wr_en       (wr_en & ~full),
        .rd_en       (rd_en & ~empty),
        .dout        (rd_data),
        .full        (full),
        .empty       (empty),
        .valid       (rd_valid),
        .wr_rst_busy (wr_rst_busy),
        .rd_rst_busy (rd_rst_busy)
    );

    assign debug_wr_level = {{ADDR_WIDTH{1'b0}}, full | wr_rst_busy};
    assign debug_rd_level = {{ADDR_WIDTH{1'b0}}, ~empty & ~rd_rst_busy};

`else

    async_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_async_fifo (
        .clk_wr         (clk_wr),
        .wr_rst_n       (wr_rst_n),
        .clk_rd         (clk_rd),
        .rd_rst_n       (rd_rst_n),
        .wr_en          (wr_en),
        .wr_data        (wr_data),
        .rd_en          (rd_en),
        .rd_data        (rd_data),
        .rd_valid       (rd_valid),
        .full           (full),
        .empty          (empty),
        .debug_wr_level (debug_wr_level),
        .debug_rd_level (debug_rd_level)
    );

`endif

endmodule
