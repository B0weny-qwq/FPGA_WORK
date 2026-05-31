# SpectrumAnalyzer 满分级补齐 Goal

## 0. 使用方式

本文档是给后续 Goal 模式或执行代理使用的目标说明。当前文档只定义目标、范围、验收标准和推荐执行顺序，不代表已经完成所有工程修改。

执行代理应以本文档为唯一高层目标来源，结合仓库当前状态实施。实施过程中如果发现 RTL、Vivado IP、脚本、文档或报告与本文档冲突，应优先保证“可仿真、可综合、电路图可解释、报告一致”。

## 1. 总目标

将 `SpectrumAnalyzer` 补齐为课程答辩满分级 FPGA 频谱分析仪工程，满足：

- Vivado 2025.2 下可一键创建工程。
- 必要 IP 核已真实生成并接入工程，不只是放在目录里。
- 4 个 testbench 可运行并通过。
- `spec_analyzer_top` 可综合成功。
- 综合或 elaborated schematic 电路图能沿数据流看出每个模块做什么。
- README、中文设计文档、验证文档、IP 接入说明、综合电路图说明全部与最终实现一致。
- LaTeX 实验报告更新到最终版，能直接用于课程提交或答辩。
- 使用 Graphify 维护项目结构图谱，方便后续继续修改 goal 和追踪模块关系。

本目标不要求真实上板，不补具体开发板管脚约束，不承诺 bitstream 可在某块板卡上直接运行。

## 2. 最终系统链路

综合电路图和文档必须能清楚表达如下链路：

```text
DDS 信号源
  -> 可选 Hann 窗
  -> 异步 FIFO
  -> FFT 帧控制
  -> Vivado FFT IP
  -> 幅度计算
  -> 峰值检测
  -> 幅度压缩 / 频谱缓存
  -> VGA 时序 / 频谱渲染 / OSD 叠加
```

每个模块的答辩解释口径：

| 模块 | 必须能说明的作用 |
| --- | --- |
| DDS 信号源 | 产生正弦、方波、三角波、锯齿波和双音测试输入 |
| Hann 窗 | 降低频谱泄漏，可开关 |
| 异步 FIFO | 完成 `clk_sample` 到 `clk_fft` 的跨时钟域缓存 |
| FFT 帧控制 | 凑够 256 点，产生 AXI-Stream `tvalid/tready/tlast` |
| FFT IP | 使用 Vivado `xfft` 完成 256 点频域变换 |
| 幅度计算 | 对复数 FFT 输出计算 `real*real + imag*imag` |
| 峰值检测 | 忽略直流频点，找到当前帧最大频点 |
| 频谱缓存 | 保存前 128 个可视频点供 VGA 读取 |
| VGA 显示链路 | 产生 640x480 风格时序、频谱柱状图和文字叠加 |

## 3. IP 补齐要求

必须真实生成并加入 Vivado 工程的 IP：

| IP 名称 | Vivado IP | 目的 | 接入要求 |
| --- | --- | --- | --- |
| `xfft_256` | `xilinx.com:ip:xfft:9.1` | 256 点 FFT | 必须接入 `xfft_wrapper` 综合路径 |
| `async_sample_fifo_ip` | `xilinx.com:ip:fifo_generator:13.2` | 异步 FIFO 展示与综合路径 | 可通过宏或封装接入，但必须能被工程识别 |
| `sine_rom_256` | `xilinx.com:ip:blk_mem_gen:8.4` | 正弦查找表 IP 化展示 | 可作为可选综合路径或文档展示 IP |
| `hann_rom_256` | `xilinx.com:ip:blk_mem_gen:8.4` | Hann 窗系数 IP 化展示 | 可作为可选综合路径或文档展示 IP |
| `spec_bin_bram` | `xilinx.com:ip:blk_mem_gen:8.4` | 频谱显示缓存 IP 化展示 | 可作为可选综合路径或文档展示 IP |

可选展示型 IP：

| IP 名称 | Vivado IP | 说明 |
| --- | --- | --- |
| `dds_compiler_ref` | `xilinx.com:ip:dds_compiler:6.0` | 用于答辩展示 DDS IP 方案；不强制替换当前多波形 DDS |
| `clk_wiz_spectrum` | `xilinx.com:ip:clk_wiz:6.0` | 用于说明真实上板时钟生成方案；默认不作为顶层必需输入 |
| `ila_spectrum_debug` | `xilinx.com:ip:ila:6.2` | 用于说明上板调试方案；默认不影响仿真 |

重要原则：

- FFT IP 必须真实接入，不允许只保留行为级 DFT 占位。
- 仿真可以继续使用 `XFFT_BEHAVIORAL_DFT_SIM`，以保证快速、稳定、自检查。
- 综合路径必须能看到真实 `xfft_256` IP。
- DDS/VGA/幅度计算/峰值检测是课程核心设计点，除非实现代理确认不破坏功能，否则不应强行全部替换成 IP。

## 4. Vivado 脚本要求

需要补齐或修正以下脚本：

| 脚本 | 作用 |
| --- | --- |
| `scripts/gen_ip_all.tcl` | 生成或读取所有计划 IP，并输出 IP 状态 |
| `scripts/setup_full_project.tcl` | 一键创建工程、导入 RTL、导入 IP、导入约束、设置顶层 |
| `scripts/run_all_sims.tcl` | 批量运行 4 个 testbench |
| `scripts/run_synth_check.tcl` | 执行综合检查并导出利用率、时序、层级、电路图相关报告 |
| `scripts/export_schematic.tcl` | 导出或辅助查看 elaborated/synthesized schematic 的结构说明材料 |

Vivado CLI 入口：

```powershell
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/setup_full_project.tcl
```

如果使用 Tcl Shell：

```tcl
cd C:/Users/S/Desktop/FPGA/SpectrumAnalyzer
source scripts/setup_full_project.tcl
source scripts/run_all_sims.tcl
source scripts/run_synth_check.tcl
```

脚本必须兼容 Vivado 把 IP 生成到 `ip/<module_name>_1/` 的情况，不能硬编码只找 `ip/<module_name>/<module_name>.xci`。

## 5. 综合电路图要求

综合电路图不是形式要求，而是核心验收项。最终工程必须能做到：

- 打开 elaborated design 或 synthesized design 后，能从 `spec_analyzer_top` 沿数据流展开。
- 图中至少能清楚识别以下层级或等价封装：
  - `dds_signal_gen`
  - `win_mul_optional`
  - `async_fifo` 或 FIFO IP 封装
  - `fft_frame_ctrl`
  - `xfft_wrapper` / `xfft_256`
  - `fft_mag_calc`
  - `peak_detector`
  - `mag_compress`
  - `spec_bin_buffer`
  - `vga_timing_gen`
  - `spectrum_renderer`
  - `osd_text_gen`
  - `overlay_mux`
- 不允许综合脚本把所有层级完全扁平化到无法答辩解释。
- 综合报告或文档中要说明哪些模块是 IP，哪些模块是手写 RTL。

建议综合脚本使用保层级策略，例如对关键层级设置 `DONT_TOUCH` 或使用适当的综合选项。具体实现由执行代理按 Vivado 实际行为决定。

## 6. 文档更新要求

必须更新或新增以下文档：

| 文件 | 要求 |
| --- | --- |
| `README.md` | 更新为最终工程入口，说明一键脚本、IP 状态、仿真/综合流程 |
| `docs/architecture.md` | 更新系统架构，明确真实 IP 接入和数据流 |
| `docs/interface_spec.md` | 更新 IP 封装接口、AXI-Stream/FIFO/BRAM 接口说明 |
| `docs/verification_plan.md` | 更新仿真、综合、IP status、schematic 验收项 |
| `docs/test_tutorial.md` | 更新 Vivado 2025.2 CLI 操作步骤 |
| `docs/ip_integration.md` | 新增，记录每个 IP 参数、路径、用途、接入点 |
| `docs/synthesis_schematic.md` | 新增，说明综合电路图如何查看、截图、讲解 |
| `docs/full_score_goal.md` | 本目标文档，后续修改 goal 时同步维护 |

文档语言以中文为主，答辩口径要直接、清楚、可照着讲。

## 7. LaTeX 实验报告要求

必须补齐或更新 LaTeX 实验报告。若仓库中不存在 `.tex` 报告，应新增一个最终版报告源文件，例如：

```text
SpectrumAnalyzer/report/report.tex
```

报告至少包含：

1. 设计目标与任务要求
2. 系统总体框图
3. 模块划分与数据流
4. IP 核配置表
5. DDS 信号源设计
6. Hann 窗与异步 FIFO 设计
7. FFT IP 接入与帧控制
8. 幅度计算、峰值检测和频谱缓存
9. VGA 显示设计
10. 仿真验证结果
11. 综合结果与电路图分析
12. 课程答辩亮点与总结

报告必须与最终工程一致，不能继续写“后续需要接入 FFT IP”这类过期描述。若生成 PDF，应放在稳定位置，例如：

```text
SpectrumAnalyzer/report/SpectrumAnalyzer_Report.pdf
```

## 8. Graphify 要求

执行代理在关键阶段运行：

```powershell
C:/AgentHarness/bin/graphify.ps1 update .
```

运行目录：

```text
C:/Users/S/Desktop/FPGA/SpectrumAnalyzer
```

Graphify 输出用于：

- 维护 `graphify-out/graph.json`
- 生成 `graphify-out/GRAPH_REPORT.md`
- 检查文档是否覆盖主要模块社区
- 后续持续修改 goal 时快速定位工程结构

注意：`graphify-out/` 可以作为本地分析产物；是否提交由执行代理根据仓库规范决定。

## 9. 验收命令

最终至少应能运行：

```powershell
cd C:/Users/S/Desktop/FPGA/SpectrumAnalyzer
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/setup_full_project.tcl
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/run_all_sims.tcl
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/run_synth_check.tcl
C:/AgentHarness/bin/graphify.ps1 update .
```

通过标准：

- Vivado 工程创建成功。
- 所有计划 IP 的 `.xci` 存在并加入工程。
- 4 个 testbench 全部通过：
  - `tb_async_fifo`
  - `tb_fft_chain`
  - `tb_vga_render`
  - `tb_spec_analyzer_top`
- `spec_analyzer_top` 综合成功。
- 生成 `reports/` 下的关键报告：
  - IP 状态报告
  - 综合利用率报告
  - 时序概要报告
  - 层级/结构说明报告
- 文档和 LaTeX 报告内容与实际工程一致。

## 10. 边界与注意事项

- 不要求真实上板。
- 不补具体开发板管脚约束。
- 不删除用户已有未确认文件。
- 不回退无关改动，例如 `Boweny/Boweny.xpr` 或仓库外报告产物。
- 如果 IP 全替换会破坏课程可解释性，优先选择“真实 IP 展示 + 稳定 RTL 主链路”的方案。
- 任何新增宏或可选路径，都必须在文档中说明默认用途：仿真、综合、展示或上板预留。

## 11. 当前已知状态提示

截至本文档创建时，仓库中已观察到：

- `xfft_256` FFT IP 已生成过，实际路径可能为 `ip/xfft_256_1/xfft_256.xci`。
- `xfft_wrapper.v` 已有真实 FFT IP 综合路径和行为级 DFT 仿真路径。
- `scripts/create_project.tcl` 与 `scripts/gen_ip_fft.tcl` 已开始兼容 `ip/*/xfft_256.xci`。
- `graphify-out/` 已由 Graphify 生成过，用于工程结构分析。
- 仍需执行代理统一脚本、补文档、补 LaTeX 报告，并做最终 Vivado 验证。

## 12. 2026-05-31 本轮实现状态

本轮已按最小侵入式原则完成以下补齐：

- 新增 `scripts/setup_full_project.tcl`、`scripts/gen_ip_all.tcl`、`scripts/run_all_sims.tcl`、`scripts/run_synth_check.tcl`、`scripts/export_schematic.tcl`，旧入口 `create_project.tcl`、`gen_ip_fft.tcl`、`setup_with_fft_ip.tcl` 保持兼容。
- 真实生成/读取并导入 `xfft_256`、`async_sample_fifo_ip`、`sine_rom_256`、`hann_rom_256`、`spec_bin_bram`。
- `xfft_wrapper` 综合路径实例化真实 `xfft_256`；仿真路径继续使用 `XFFT_BEHAVIORAL_DFT_SIM` 行为级 DFT，保证自检稳定。
- 新增 `async_fifo_bridge`，默认保持手写 `async_fifo` 主链路；定义 `USE_ASYNC_SAMPLE_FIFO_IP` 时可选接入 FIFO Generator IP。
- 已运行 Vivado 2025.2：一键工程创建通过，4 个 testbench 全部通过，`spec_analyzer_top` 综合通过，`open_run synth_1` 时读取 `ip/xfft_256_1/xfft_256.dcp`。
- 已更新 README、架构、接口、验证、教程、IP 接入、电路图说明，并新增 `report/report.tex`。
- 本轮后续仍需继续维护 Graphify 图谱，并在后续修改后同步更新本状态段和相关文档。
