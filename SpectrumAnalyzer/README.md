# FPGA 频谱分析仪课程设计

## 1. 项目简介

`SpectrumAnalyzer` 是一个面向课程答辩的 FPGA 频谱分析仪工程，默认工具链为 Vivado 2025.2。工程目标是展示一条可仿真、可综合、电路图层级清楚的频谱分析链路，不要求真实上板，也不补具体开发板管脚约束。

最终数据流如下：

```text
DDS 信号源
  -> 可选 Hann 窗
  -> 异步 FIFO
  -> FFT 帧控制
  -> Vivado xfft_256 FFT IP
  -> 幅度计算
  -> 峰值检测
  -> 幅度压缩 / 频谱缓存
  -> VGA 时序 / 频谱渲染 / OSD 叠加
```

答辩时可以直接说明：DDS 负责产生正弦、方波、三角波、锯齿波和双音测试输入；Hann 窗降低频谱泄漏；FIFO 完成 `clk_sample` 到 `clk_fft` 的跨时钟域缓存；`xfft_wrapper` 在综合路径中接入真实 Vivado `xfft_256` IP；后处理计算功率幅度、检测非直流峰值并写入显示缓存；VGA 链路把前 128 个频点显示成柱状频谱和 OSD 状态文字。

## 2. 当前验收状态

已在本机 Vivado 2025.2 下执行：

- `scripts/setup_full_project.tcl`：创建工程并导入 RTL、testbench 和 5 个计划 IP。
- `scripts/run_all_sims.tcl`：4 个 testbench 全部通过。
- `scripts/run_synth_check.tcl`：`spec_analyzer_top` 综合完成，0 error、0 critical warning，并在 `open_run synth_1` 时读入 `ip/xfft_256_1/xfft_256.dcp`。
- `C:/AgentHarness/bin/graphify.ps1 update .`：用于维护 `graphify-out/` 项目结构图谱。

Vivado 控制台在 Windows 批处理模式下可能显示中文乱码，但脚本逻辑、RTL 文件和正式 Markdown 文档均按 UTF-8 维护。

## 3. 一键流程

在 PowerShell 中运行：

```powershell
cd C:/Users/S/Desktop/FPGA/SpectrumAnalyzer
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/setup_full_project.tcl
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/run_all_sims.tcl
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/run_synth_check.tcl
C:/AgentHarness/bin/graphify.ps1 update .
```

如果已经在 Vivado Tcl Shell 中，可以执行：

```tcl
cd C:/Users/S/Desktop/FPGA/SpectrumAnalyzer
source scripts/setup_full_project.tcl
source scripts/run_all_sims.tcl
source scripts/run_synth_check.tcl
```

## 4. 脚本说明

| 脚本 | 作用 |
| --- | --- |
| `scripts/setup_full_project.tcl` | 一键创建 Vivado 工程，导入 RTL、testbench、计划 IP，并设置顶层 |
| `scripts/gen_ip_all.tcl` | 生成或读取 `xfft_256`、FIFO、ROM、BRAM 等计划 IP，并写出 `reports/ip_status.md` |
| `scripts/run_all_sims.tcl` | 批量运行 `tb_async_fifo`、`tb_fft_chain`、`tb_vga_render`、`tb_spec_analyzer_top` |
| `scripts/run_synth_check.tcl` | 运行 `synth_1`，导出利用率、时序、层级、编译顺序和 checkpoint |
| `scripts/export_schematic.tcl` | 生成电路图查看说明，并辅助导出 elaborated hierarchy |
| `scripts/fix_project_sources.tcl` | 修复旧 GUI 工程未导入新增 RTL/IP 时的 source 引用 |
| `scripts/create_project.tcl` | 旧入口兼容脚本，内部调用 `setup_full_project.tcl` |
| `scripts/gen_ip_fft.tcl` | 旧入口兼容脚本，内部调用 `gen_ip_all.tcl` |

如果 Vivado GUI 综合时报 `module 'async_fifo_bridge' not found`，先确认当前打开的工程文件。`Boweny/Boweny.xpr` 也引用了本工程顶层，必须在 `sources_1` 中包含：

- `../SpectrumAnalyzer/rtl/fifo/async_fifo_bridge.v`
- `../SpectrumAnalyzer/ip/xfft_256_1/xfft_256.xci`

当前仓库中的 `Boweny/Boweny.xpr` 已补齐这两个条目，并已用该工程直接综合通过。若打开的是 `SpectrumAnalyzer/vivado_project/spectrum_analyzer.xpr`，可在 Tcl Console 中执行：

```tcl
cd C:/Users/S/Desktop/FPGA/SpectrumAnalyzer
source scripts/fix_project_sources.tcl
reset_run synth_1
launch_runs synth_1 -jobs 2
```

也可以直接重新运行 `scripts/setup_full_project.tcl` 重建工程。本地已用 `scripts/run_synth_check.tcl` 重新综合确认：`async_fifo_bridge` 可被识别，综合结果为 0 error。

## 5. IP 状态

| IP 名称 | 用途 | 默认接入方式 |
| --- | --- | --- |
| `xfft_256` | 256 点 Vivado FFT | 综合路径真实接入 `xfft_wrapper` |
| `async_sample_fifo_ip` | 异步 FIFO IP 展示 | 默认不启用；定义 `USE_ASYNC_SAMPLE_FIFO_IP` 时经 `async_fifo_bridge` 接入 |
| `sine_rom_256` | 正弦查找表 IP 化展示 | 导入工程，用于说明 DDS ROM 可 IP 化 |
| `hann_rom_256` | Hann 系数 ROM IP 化展示 | 导入工程，用于说明窗口系数 ROM 可 IP 化 |
| `spec_bin_bram` | 频谱缓存 BRAM IP 化展示 | 导入工程，用于说明显示缓存可 BRAM IP 化 |

默认仿真定义 `XFFT_BEHAVIORAL_DFT_SIM`，`xfft_wrapper` 使用行为级 DFT 模型，保证 testbench 快速稳定；综合不定义该宏，因此 `xfft_wrapper` 实例化真实 `xfft_256` IP。

## 6. 工程目录

```text
SpectrumAnalyzer/
|-- README.md
|-- rtl/
|   |-- top/          spec_analyzer_top
|   |-- common/       时钟、复位、同步
|   |-- ctrl/         仿真控制模型
|   |-- dds/          DDS 多波形信号源
|   |-- window/       Hann 窗
|   |-- fifo/         手写 FIFO 与 async_fifo_bridge
|   |-- fft/          帧控制、FFT 配置、xfft_wrapper
|   |-- postproc/     幅度、峰值、压缩、频谱缓存
|   |-- vga/          VGA 时序、渲染、OSD、叠加
|   `-- sim_model/    仿真辅助模型
|-- sim/tb/           4 个 SystemVerilog testbench
|-- scripts/          Vivado 批处理脚本
|-- ip/               Vivado IP XCI 与生成产物
|-- docs/             中文设计、接口、验证、IP、电路图说明
|-- report/           LaTeX 实验报告源文件
|-- reports/          本地仿真/综合/IP 状态报告
`-- graphify-out/     Graphify 项目结构图谱
```

## 7. 文档入口

- [系统架构说明](docs/architecture.md)
- [接口说明](docs/interface_spec.md)
- [验证计划](docs/verification_plan.md)
- [测试教程](docs/test_tutorial.md)
- [IP 接入说明](docs/ip_integration.md)
- [综合电路图说明](docs/synthesis_schematic.md)
- [满分级补齐 Goal](docs/full_score_goal.md)

LaTeX 报告源文件位于 `report/report.tex`。
