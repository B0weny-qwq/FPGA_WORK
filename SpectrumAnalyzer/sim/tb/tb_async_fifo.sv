// 模块名: tb_async_fifo
// 功能: 异步 FIFO 独立仿真测试
// 时钟域: clk_wr 和 clk_rd
// 输入: 无外部输入，testbench 内部产生激励
// 输出: 控制台中文通过/失败信息
// 说明: 检查基础写读顺序、empty/full 状态和 rd_valid 时序

// 预期结果:
//   1. 写入 12 个数据时 FIFO 不应提前 full。
//   2. 读出数据顺序应依次为 100 到 111，rd_valid 有效时数据必须匹配。
//   3. 全部读出后 empty 应为 1，errors 保持为 0。
//   4. 控制台最终打印“通过：异步 FIFO 数据顺序和空满检查正确”。

`timescale 1ns / 1ps

module tb_async_fifo;

    localparam DATA_WIDTH = 16;
    localparam ADDR_WIDTH = 4;
    localparam TEST_COUNT = 12;

    reg clk_wr;
    reg clk_rd;
    reg wr_rst_n;
    reg rd_rst_n;
    reg wr_en;
    reg rd_en;
    reg signed [DATA_WIDTH-1:0] wr_data;

    wire signed [DATA_WIDTH-1:0] rd_data;
    wire rd_valid;
    wire full;
    wire empty;
    wire [ADDR_WIDTH:0] debug_wr_level;
    wire [ADDR_WIDTH:0] debug_rd_level;

    integer write_idx;
    integer read_idx;
    integer errors;

    async_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) dut (
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

    initial begin
        clk_wr = 1'b0;
        forever #50 clk_wr = ~clk_wr;
    end

    initial begin
        clk_rd = 1'b0;
        forever #35 clk_rd = ~clk_rd;
    end

    initial begin
        wr_rst_n = 1'b0;
        rd_rst_n = 1'b0;
        wr_en = 1'b0;
        rd_en = 1'b0;
        wr_data = '0;
        write_idx = 0;
        read_idx = 0;
        errors = 0;

        repeat (6) @(posedge clk_wr);
        wr_rst_n = 1'b1;
        rd_rst_n = 1'b1;

        repeat (3) @(posedge clk_wr);

        for (write_idx = 0; write_idx < TEST_COUNT; write_idx = write_idx + 1) begin
            @(posedge clk_wr);
            wr_en <= 1'b1;
            wr_data <= write_idx + 16'd100;

            if (full) begin
                errors = errors + 1;
                $display("错误：基础写入阶段 FIFO 不应提前 full");
            end
        end

        @(posedge clk_wr);
        wr_en <= 1'b0;

        repeat (8) @(posedge clk_rd);
        rd_en <= 1'b1;

        wait (read_idx == TEST_COUNT);
        @(posedge clk_rd);
        rd_en <= 1'b0;

        repeat (8) @(posedge clk_rd);

        if (!empty) begin
            errors = errors + 1;
            $display("错误：全部读出后 FIFO 应为空");
        end

        if (errors == 0) begin
            $display("通过：异步 FIFO 数据顺序和空满检查正确");
        end else begin
            $fatal(1, "失败：tb_async_fifo 共发现 %0d 个错误", errors);
        end

        $finish;
    end

    always @(posedge clk_rd) begin
        if (rd_valid) begin
            if (rd_data !== (read_idx + 16'd100)) begin
                errors = errors + 1;
                $display("错误：第 %0d 次读取，期望 %0d，实际 %0d",
                         read_idx, read_idx + 100, rd_data);
            end

            read_idx = read_idx + 1;
        end
    end

endmodule
