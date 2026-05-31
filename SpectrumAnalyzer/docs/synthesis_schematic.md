# 综合电路图说明

## 1. 验收目标

综合电路图的目标不是只生成一张截图，而是能够从 `spec_analyzer_top` 沿数据流解释每个模块做什么。当前综合脚本使用 `flatten_hierarchy none`，尽量保留层级，便于答辩展开。

## 2. 生成综合结果

```powershell
cd C:/Users/S/Desktop/FPGA/SpectrumAnalyzer
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/run_synth_check.tcl
```

生成的关键文件：

| 文件 | 用途 |
| --- | --- |
| `reports/synth_utilization.rpt` | 资源利用率 |
| `reports/timing_summary.rpt` | 时序概要 |
| `reports/hierarchy.rpt` | 层级列表 |
| `reports/compile_order.rpt` | 编译顺序 |
| `reports/spec_analyzer_top_synth.dcp` | 可重新打开的综合 checkpoint |

## 3. Vivado GUI 查看步骤

1. 打开 `vivado_project/spectrum_analyzer.xpr`。
2. 选择 `Open Elaborated Design`，先看 RTL 展开结构。
3. 运行或打开 `synth_1` 后，选择 `Open Synthesized Design`。
4. 在 Schematic 中从 `spec_analyzer_top` 展开主链路。

建议截图顺序：

```text
spec_analyzer_top
  -> u_dds_signal_gen
  -> u_win_mul_optional
  -> u_async_fifo_bridge / u_async_fifo
  -> u_fft_frame_ctrl
  -> u_xfft_wrapper / u_xfft_256
  -> u_fft_mag_calc
  -> u_peak_detector / u_mag_compress
  -> u_spec_bin_buffer
  -> u_vga_timing_gen / u_spectrum_renderer / u_osd_text_gen / u_overlay_mux
```

## 4. 答辩讲解口径

- `dds_signal_gen`：内部有相位累加器和多波形生成模块，是测试信号源。
- `win_mul_optional`：窗口关闭时旁路，开启时乘 Hann 系数，降低频谱泄漏。
- `async_fifo_bridge`：默认接手写 FIFO，说明跨时钟域缓存；可选宏可切换到 FIFO IP。
- `fft_frame_ctrl`：把 FIFO 样本整理成 256 点 AXI-Stream 帧。
- `xfft_wrapper`：封装 Vivado `xfft_256`，使外部模块不依赖 IP 细节。
- `fft_mag_calc`：把复数频域结果变成功率幅度。
- `peak_detector`：忽略直流，找每帧最大频点。
- `mag_compress/spec_bin_buffer`：把幅度压缩成显示高度并缓存前 128 个频点。
- `vga_*`：产生时序、频谱柱状图、OSD 文字和 RGB 叠加。

## 5. IP 与 RTL 标注

综合图中应明确说明：

| 类型 | 模块 |
| --- | --- |
| 真实 IP | `u_xfft_wrapper/u_xfft_256` |
| 可选/展示 IP | `async_sample_fifo_ip`、`sine_rom_256`、`hann_rom_256`、`spec_bin_bram` |
| 手写 RTL | DDS、Hann 窗默认 ROM、默认异步 FIFO、帧控制、幅度/峰值/压缩、VGA |

Vivado 综合报告中 `Report BlackBoxes` 可能显示 `xfft_256`，这是 IP OOC checkpoint 被顶层综合网表引用的正常表现；`open_run synth_1` 时会读取 `ip/xfft_256_1/xfft_256.dcp` 并绑定到 `u_xfft_wrapper/u_xfft_256`。
