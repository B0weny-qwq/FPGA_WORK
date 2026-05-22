# FPGA 频谱分析仪课程设计

本仓库是一个面向 Vivado 仿真演示的 FPGA 频谱分析仪课程设计工程。系统使用 Verilog/SystemVerilog 编写，核心链路为：

```text
DDS 信号源 -> Hann 窗 -> 异步 FIFO -> FFT 帧控制 -> FFT/DFT 模型
           -> 幅度计算 -> 峰值检测 -> 频谱缓存 -> VGA 风格显示
```

工程目标是完成一条结构清晰、可解释、可仿真的频谱分析链路，便于课程报告和答辩展示。当前版本以仿真为主，不包含真实 ADC、UART、按键消抖和完整板级约束。

## 工程目录

```text
FPGA/
|-- README.md                    仓库总览
|-- .gitignore                   忽略本地报告源文件和 Vivado 生成产物
|-- .gitattributes               将 PDF/PNG 按二进制文件处理
|-- SpectrumAnalyzer/            频谱分析仪源码、脚本和文档
|   |-- README.md                详细设计说明
|   |-- rtl/                     Verilog RTL 源码
|   |-- sim/tb/                  SystemVerilog testbench
|   |-- scripts/                 Vivado Tcl 脚本
|   `-- docs/                    架构、接口、验证和教程文档
|-- Boweny/
|   `-- Boweny.xpr               Vivado 工程入口文件
|-- image/                       报告和 README 使用的截图
`-- assets/
    `-- report.pdf               导出的课程报告
```

`assets/report.typ` 已被忽略，不提交到仓库。该文件包含本机图片路径，下载到其他电脑后容易因为路径不同导致编译失败；仓库中保留 `assets/report.pdf` 作为可直接阅读的报告版本。

## 主要模块

- `SpectrumAnalyzer/rtl/dds/`：DDS 波形发生器，支持正弦、方波、三角波和锯齿波。
- `SpectrumAnalyzer/rtl/window/`：可选 Hann 窗处理。
- `SpectrumAnalyzer/rtl/fifo/`：异步 FIFO 和 Gray 指针跨时钟域同步。
- `SpectrumAnalyzer/rtl/fft/`：FFT 帧控制与 FFT 封装，仿真时可使用行为级 DFT 模型。
- `SpectrumAnalyzer/rtl/postproc/`：幅度计算、峰值检测、幅度压缩和频谱缓存。
- `SpectrumAnalyzer/rtl/vga/`：640x480 VGA 时序、频谱柱状图渲染和文字叠加。
- `SpectrumAnalyzer/rtl/top/spec_analyzer_top.v`：系统顶层。

## 仿真入口

Vivado 中打开 `Boweny/Boweny.xpr`，或在 Vivado Tcl Console 中进入 `SpectrumAnalyzer` 目录后执行：

```tcl
source scripts/create_project.tcl
```

默认顶层 testbench 为 `tb_spec_analyzer_top`。如需切换仿真顶层：

```tcl
set sim_top tb_async_fifo
source scripts/run_sim.tcl
```

可用 testbench：

- `tb_async_fifo.sv`：验证 FIFO 读写顺序、空满标志和 `rd_valid`。
- `tb_fft_chain.sv`：验证 DDS 到 FFT 后处理链路，单音主峰应在预期频点附近。
- `tb_vga_render.sv`：验证 VGA 有效像素计数和频谱渲染输出。
- `tb_spec_analyzer_top.sv`：顶层端到端仿真，检查峰值结果和 VGA 输出。

每个 testbench 文件顶部都写有对应的预期结果，打开文件即可查看该仿真应该观察什么。

## 推荐查看信号

- DDS：`sample_valid`、`sample_data`、`wave_sel`、`freq_word`
- FIFO：`full`、`empty`、`rd_valid`、读写指针
- FFT 输入：`tvalid`、`tready`、`tlast`
- 后处理：`mag_valid`、`mag_bin`、`peak_bin`、`peak_valid`
- VGA：`active_video`、`pixel_x`、`pixel_y`、`vga_r/g/b`

## 文档

更详细的设计说明见：

- `SpectrumAnalyzer/README.md`
- `SpectrumAnalyzer/docs/architecture.md`
- `SpectrumAnalyzer/docs/interface_spec.md`
- `SpectrumAnalyzer/docs/verification_plan.md`
- `SpectrumAnalyzer/docs/test_tutorial.md`
