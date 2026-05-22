= FPGA 频谱分析仪课程设计

== 1. 项目简介

本工程是一个面向仿真演示的 FPGA 频谱分析仪课程设计，使用 Verilog/SystemVerilog 编写，默认工具链为 Vivado。工程目标不是上板部署，而是完成一条结构清晰、可解释、可仿真的频谱分析链路，便于课程答辩展示波形、模块接口和验证过程。

一句话说明：本工程先用 DDS 在 FPGA 里造一个可控测试波形，再把这串采样送进 FFT，算出哪个频率最强，最后把频谱结果送到 VGA 风格显示模块。

系统固定数据路线如下：

```text
DDS 信号源 -> 可选 Hann 窗 -> 异步 FIFO -> FFT 帧控制 -> FFT 封装
           -> 幅度计算/峰值检测 -> 频谱缓存 -> VGA 风格显示
```

更直观的模块图如下：

```text
testbench
  产生时钟、复位、控制
        |
        v
spec_analyzer_top 顶层
        |
        v
DDS 信号源
  正弦 / 方波 / 三角波 / 锯齿波
        |
        v
Hann 窗
  可开可关，用于降低频谱泄漏
        |
        v
异步 FIFO
  clk_sample 低速采样域 -> clk_fft 高速处理域
        |
        v
FFT 帧控制
  凑够 256 点，并在最后一点产生 tlast
        |
        v
FFT 封装
  仿真用 DFT 模型，综合时可替换 Vivado FFT IP
        |
        v
幅度计算
  real * real + imag * imag
        |
        +------------------+
        |                  |
        v                  v
峰值检测              幅度压缩
找最大频点            变成显示高度
        |                  |
        v                  v
debug_peak_*       频谱缓存 -> VGA 渲染 -> RGB/HS/VS
```

从考试题目对应关系看，本工程选择的是“频谱仪设计”这个进阶题，同时用到了 DDS、异步 FIFO 和 VGA 显示：

```text
第 5 题频谱仪
|-- DDS 信号源：对应第 4 题波形发生器
|-- 异步 FIFO：对应第 3 题跨时钟域缓存
|-- FFT / 幅度 / 峰值：对应第 5 题核心
`-- VGA 频谱显示：对应第 2 题图形叠加显示
```

本版本的 `xfft_wrapper` 在仿真文件集中启用行为级 DFT 模型，方便没有生成 Vivado FFT IP 时进行系统级联调；综合时默认切换为可综合的 AXI-Stream 占位通路，避免行为级数学函数进入 synthesis。后续如果需要接入真正的 Xilinx FFT IP，只需要修改 `rtl/fft/xfft_wrapper.v` 这一处接口封装。

== 2. 波形怎么看

先在 Vivado Wave 里把关键信号的 Radix 改成人能看的格式：

#table(
  columns: (1.4fr, 1.4fr, 3fr),
  inset: 6pt,
  align: left,
  [信号], [Radix 建议], [你要看什么],
  [`errors`], [Unsigned Decimal], [必须是 0，表示 testbench 没发现错误],
  [`peak_count`], [Unsigned Decimal], [大于 0，表示已经检测到频谱峰值],
  [`debug_peak_valid`], [Binary], [出现 1 时，说明当前峰值结果有效],
  [`debug_peak_bin`], [Unsigned Decimal], [峰值频点编号，例如 5 表示第 5 个频点最强],
  [`debug_peak_mag`], [Unsigned Decimal], [峰值幅度，不能一直是 0],
  [`debug_fft_bin`], [Unsigned Decimal], [应该从 0 跑到 255，表示一帧 256 点 FFT 输出完成],
  [`debug_fifo_full`], [Binary], [不应长期为 1],
  [`debug_fifo_empty`], [Binary], [可短暂为 1，但不应和 full 同时为 1],
  [`wave_sel`], [Unsigned Decimal], [0 正弦，1 方波，2 三角，3 锯齿],
  [`freq_word`], [Hexadecimal], [看当前 DDS 频率控制字，例如 `08000000`],
  [`vga_r/g/b`], [Hexadecimal], [RGB 不应永远全 0，说明显示层有输出],
)

一张合格的顶层仿真截图，至少能说明下面几件事：

```text
errors = 0                  没报错
peak_count > 0              检测到过峰值
debug_peak_valid = 1        当前峰值结果有效
debug_peak_bin 有十进制数   找到了最大频点
debug_peak_mag 非 0         频谱有能量
debug_fft_bin 到 255        一帧 256 点输出完成
```

如果老师问“这张波形测试什么”，可以直接回答：

#quote(block: true)[
这是顶层端到端仿真，验证 DDS 产生的测试信号经过异步 FIFO、FFT、幅度计算和峰值检测后，可以输出有效频谱峰值，且系统没有检测错误。
]

== 3. 设计边界

本工程包含：

- 内部 DDS 测试信号源；
- 多时钟域仿真；
- 异步 FIFO 跨时钟域；
- 256 点 FFT 帧控制；
- 复数 FFT 输出幅度计算；
- 单帧峰值频点检测；
- 128 个可视频点缓存；
- 640x480 VGA 风格时序、频谱柱状图和文字叠加；
- 独立 testbench 和中文验证文档。

本工程不包含：

- 外部 ADC 硬件采样；
- 真实 UART 收发；
- 真实按键消抖；
- 板级约束文件完善；
- 必须上板运行的流程。

== 4. 推荐参数

#table(
  columns: (1fr, 1.6fr),
  inset: 6pt,
  align: left,
  [项目], [参数],
  [FFT 点数], [256],
  [DDS 样本位宽], [16 位有符号],
  [FFT 输入格式], [`{imag[15:0], real[15:0]}`],
  [样本时钟], [10 MHz],
  [FFT 时钟], [50 MHz],
  [像素时钟], [25 MHz],
  [VGA 分辨率], [640x480],
  [显示频点数], [128],
)

== 5. 工程目录

```text
FPGA/
|-- .gitignore
|-- SpectrumAnalyzer/
|   |-- README.md
|   |-- rtl/                     设计源码目录
|   |   |-- top/                 顶层模块
|   |   |-- common/              时钟、复位和同步公共模块
|   |   |-- ctrl/                仿真控制模型
|   |   |-- dds/                 DDS 波形发生器
|   |   |-- window/              Hann 窗处理
|   |   |-- fifo/                异步 FIFO 与 Gray 指针同步
|   |   |-- fft/                 FFT 帧控制与 FFT 封装
|   |   |-- postproc/            幅度计算、峰值检测和频谱缓存
|   |   |-- vga/                 VGA 时序、频谱渲染和文字叠加
|   |   `-- sim_model/           仿真辅助模型
|   |-- sim/
|   |   `-- tb/                  四个 SystemVerilog testbench
|   |       |-- tb_async_fifo.sv
|   |       |-- tb_fft_chain.sv
|   |       |-- tb_vga_render.sv
|   |       `-- tb_spec_analyzer_top.sv
|   |-- scripts/
|   |   |-- create_project.tcl    创建 Vivado 工程
|   |   |-- gen_ip_fft.tcl        生成 Vivado FFT IP
|   |   `-- run_sim.tcl          切换并运行仿真顶层
|   `-- docs/
|       |-- architecture.md       架构说明
|       |-- interface_spec.md     模块接口说明
|       |-- verification_plan.md  验证计划
|       `-- test_tutorial.md      仿真操作教程
|-- image/                       README/报告截图素材
|-- assets/
|   `-- report.pdf               导出的课程报告
`-- Boweny/                      本地 Vivado 工程目录，缓存和运行产物不提交
```

`report.typ` 不提交到仓库。该文件里包含本机图片路径，其他电脑下载后直接编译容易因为路径不一致报错；仓库保留导出的 `assets/report.pdf` 作为可阅读版本。

== 6. 模块说明

=== DDS 与窗口

`phase_acc` 按频率控制字累加相位，`dds_signal_gen` 根据相位产生正弦波、方波、三角波和锯齿波。双音模式会把第二个正弦分量与主波形平均相加，避免简单相加导致溢出。`win_mul_optional` 在窗口开启时使用 Q1.15 Hann 系数进行乘法缩放，关闭时直接旁路原始样本。

=== 异步 FIFO

`async_fifo` 负责从 `clk_sample` 到 `clk_fft` 的跨时钟域传输。写控制、读控制、存储阵列和 Gray 指针同步分别拆成独立文件，便于报告中解释空满判断和 CDC 设计。

=== FFT 链路

`fft_frame_ctrl` 从 FIFO 读取样本，保证每帧正好 256 点，并在最后一个样本置位 `tlast`。`xfft_wrapper` 隔离 Vivado FFT IP 接口：仿真时使用行为级 DFT 模型，综合时使用可综合占位通路；真实频谱综合或上板时应替换为 Vivado FFT IP。

=== 后处理

`fft_mag_calc` 将 `{imag, real}` 格式的 FFT 输出解包，计算 `real * real + imag * imag`。`peak_detector` 忽略直流频点，检测每帧最大幅度频点。`mag_compress` 将 32 位幅度压缩为 8 位显示高度。

=== VGA 显示

`vga_timing_gen` 产生 640x480 有效显示区域和同步信号。`spectrum_renderer` 将 128 个频点映射成柱状图。`osd_text_gen` 显示波形类型、FFT 点数、峰值频点和窗口状态。`overlay_mux` 按“文字优先、频谱其次、背景最后”的顺序合成 RGB。

== 7. 仿真入口

#table(
  columns: (1.4fr, 3fr),
  inset: 6pt,
  align: left,
  [Testbench], [作用],
  [`tb_async_fifo.sv`], [独立验证 FIFO 读写顺序、空满标志和 `rd_valid`],
  [`tb_fft_chain.sv`], [验证 DDS、FIFO、FFT、幅度和峰值检测链路],
  [`tb_vga_render.sv`], [验证 VGA 有效像素计数和频谱渲染输出],
  [`tb_spec_analyzer_top.sv`], [顶层端到端仿真，观察峰值频点和 VGA 输出变化],
)

详细操作步骤见 `docs/test_tutorial.md`。

== 8. Vivado 使用方式

在 Vivado Tcl Console 中进入工程根目录后执行：

```tcl
source scripts/create_project.tcl
```

默认仿真顶层是 `tb_spec_analyzer_top`。如果要切换仿真顶层：

```tcl
set sim_top tb_async_fifo
source scripts/run_sim.tcl
```

如果需要生成真正的 Vivado FFT IP：

```tcl
source scripts/gen_ip_fft.tcl
```

生成 IP 后，只需要在 `rtl/fft/xfft_wrapper.v` 内替换综合占位通路或仿真行为模型部分，外部模块接口保持不变。

== 9. 答辩建议

建议展示以下波形：

- DDS：`sample_valid`、`sample_data`、`wave_sel`、`freq_word`；
- FIFO：`full`、`empty`、`rd_valid`、读写指针；
- FFT 输入：`tvalid`、`tready`、`tlast`；
- FFT 输出与后处理：`mag_valid`、`mag_bin`、`peak_bin`、`peak_valid`；
- VGA：`active_video`、`pixel_x`、`pixel_y`、`vga_r/g/b`。

报告可以直接参考 `docs/architecture.md`、`docs/interface_spec.md` 和 `docs/verification_plan.md`。
