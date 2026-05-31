# 中文测试教程

## 1. 创建完整 Vivado 工程

在 PowerShell 中执行：

```powershell
cd C:/Users/S/Desktop/FPGA/SpectrumAnalyzer
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/setup_full_project.tcl
```

脚本会创建 `vivado_project/`，导入 `rtl/`、`sim/tb/` 和 `ip/` 下的计划 IP，并把设计顶层设置为 `spec_analyzer_top`，默认仿真顶层设置为 `tb_spec_analyzer_top`。

在 Vivado Tcl Shell 中也可以执行：

```tcl
cd C:/Users/S/Desktop/FPGA/SpectrumAnalyzer
source scripts/setup_full_project.tcl
```

## 2. 批量运行 4 个 testbench

```powershell
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/run_all_sims.tcl
```

脚本会依次运行：

- `tb_async_fifo`
- `tb_fft_chain`
- `tb_vga_render`
- `tb_spec_analyzer_top`

通过后会写出 `reports/sim_summary.md`。Vivado 控制台若显示中文乱码，只看退出码和报告即可。

## 3. 单独运行某个 testbench

如果已经在 Vivado Tcl Shell 中：

```tcl
source scripts/setup_full_project.tcl
set sim_top tb_async_fifo
source scripts/run_sim.tcl
```

可把 `sim_top` 改成 `tb_fft_chain`、`tb_vga_render` 或 `tb_spec_analyzer_top`。

## 4. 各测试通过标准

### FIFO 测试

`tb_async_fifo` 写入 12 个连续数据，检查读出顺序、`rd_valid` 时序和最终 `empty` 状态。通过时控制台打印 FIFO 顺序和空满检查正确。

### FFT 链测试

`tb_fft_chain` 使用 `freq_word = 32'h0800_0000` 产生单音正弦。256 点 FFT 的主峰应接近第 8 个频点，或接近镜像频点 248。当前行为级 DFT 仿真检测到 `peak_bin=8`。

### VGA 测试

`tb_vga_render` 统计一帧有效像素数量，要求等于 `640 * 480`，并且频谱渲染器产生柱状图或网格像素。

### 顶层测试

`tb_spec_analyzer_top` 等待至少两次 `debug_peak_valid`，检查 `debug_peak_mag` 非 0，且 FIFO 不会同时 `full` 和 `empty`。当前顶层仿真两次峰值均落在频点 8。

## 5. 综合检查

```powershell
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/run_synth_check.tcl
```

脚本会运行 `synth_1`，导出：

- `reports/synth_utilization.rpt`
- `reports/timing_summary.rpt`
- `reports/hierarchy.rpt`
- `reports/compile_order.rpt`
- `reports/spec_analyzer_top_synth.dcp`
- `reports/synth_summary.md`

综合时不定义 `XFFT_BEHAVIORAL_DFT_SIM`，因此 `xfft_wrapper` 接入真实 `xfft_256` IP。Vivado `open_run synth_1` 时会读取 `ip/xfft_256_1/xfft_256.dcp`。

## 6. 电路图查看

```powershell
D:/FPGA/2025.2/Vivado/bin/vivado.bat -mode batch -source scripts/export_schematic.tcl
```

该脚本会写出 `reports/schematic_guide.md`。答辩时建议在 Vivado GUI 中打开工程，查看 elaborated 或 synthesized design，并按 README 中的数据流展开模块层级。
