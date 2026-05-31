# 验证计划

## 1. 验证目标

本工程按“可仿真、可综合、IP 真实接入、电路图可解释、文档一致”进行验收。当前推荐命令为：

```powershell
cd C:/Users/S/Desktop/FPGA/SpectrumAnalyzer
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/setup_full_project.tcl
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/run_all_sims.tcl
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/run_synth_check.tcl
C:/AgentHarness/bin/graphify.ps1 update .
```

## 2. 静态检查

- RTL 顶层链路是否包含 DDS、Hann 窗、FIFO、FFT 帧控制、FFT IP 封装、幅度计算、峰值检测、压缩、频谱缓存、VGA。
- `ip/` 下是否存在计划 IP 的 `.xci`。
- `xfft_wrapper` 在综合路径是否实例化 `xfft_256`。
- `async_fifo_bridge` 默认是否仍走手写 `async_fifo`，可选宏是否只影响 FIFO IP 展示路径。
- `scripts/run_synth_check.tcl` 是否使用 `flatten_hierarchy none` 保留层级。
- README、`docs/` 和 `report/report.tex` 是否与实际实现一致。

## 3. Testbench

| Testbench | 验证内容 | 当前结果 |
| --- | --- | --- |
| `tb_async_fifo` | 手写异步 FIFO 写读顺序、`empty/full`、`rd_valid` | 通过 |
| `tb_fft_chain` | DDS -> Hann -> FIFO -> 行为级 DFT -> 幅度 -> 峰值 | 通过，单音主峰为频点 8 |
| `tb_vga_render` | VGA 有效像素计数和频谱渲染输出 | 通过 |
| `tb_spec_analyzer_top` | 顶层端到端链路、峰值输出、FIFO 状态 | 通过 |

仿真使用 `XFFT_BEHAVIORAL_DFT_SIM`，目的是让自检快速稳定。综合验收另行确认 `xfft_256` IP。

## 4. 综合检查

`scripts/run_synth_check.tcl` 执行 `synth_1`，并导出：

| 文件 | 说明 |
| --- | --- |
| `reports/synth_utilization.rpt` | 综合资源利用率 |
| `reports/timing_summary.rpt` | 时序概要 |
| `reports/hierarchy.rpt` | 层级/结构说明 |
| `reports/compile_order.rpt` | 编译顺序 |
| `reports/spec_analyzer_top_synth.dcp` | 综合 checkpoint |
| `reports/synth_summary.md` | 综合摘要 |

当前 Vivado 2025.2 综合结果为：`spec_analyzer_top` 完成综合，0 error、0 critical warning。打开综合 run 时，Vivado 读取 `ip/xfft_256_1/xfft_256.dcp`，对应单元为 `u_xfft_wrapper/u_xfft_256`。

## 5. IP 状态检查

`scripts/gen_ip_all.tcl` 会生成或读取以下 IP，并写出 `reports/ip_status.md`：

- `xfft_256`
- `async_sample_fifo_ip`
- `sine_rom_256`
- `hann_rom_256`
- `spec_bin_bram`

验收时重点说明：`xfft_256` 是综合主链路真实使用的 IP；其他 IP 是可选/展示型 IP，已加入工程用于答辩说明。

## 6. 电路图验收

在 Vivado 中打开 elaborated design 或 synthesized design，从 `spec_analyzer_top` 沿数据流展开，至少应能识别：

- `dds_signal_gen`
- `win_mul_optional`
- `async_fifo_bridge` / `async_fifo`
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

截图或报告中应明确标注哪些是手写 RTL，哪些是真实 IP 或展示 IP。
