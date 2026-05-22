# 中文测试教程

## 1. 创建 Vivado 工程

打开 Vivado，进入 Tcl Console，将当前目录切到 `SpectrumAnalyzer` 工程根目录，然后执行：

```tcl
source scripts/create_project.tcl
```

脚本会自动创建工程、导入 `rtl/` 下的设计文件和 `sim/tb/` 下的 testbench 文件，并把默认仿真顶层设置为 `tb_spec_analyzer_top`。

## 2. 运行顶层仿真

默认运行顶层端到端仿真：

```tcl
source scripts/run_sim.tcl
```

仿真中重点观察：

- `debug_peak_valid` 是否周期性拉高；
- `debug_peak_bin` 是否随 DDS 频率设置变化；
- `debug_peak_mag` 是否为非零；
- `debug_fifo_full` 和 `debug_fifo_empty` 是否不会同时为高；
- VGA 输出 `vga_hs`、`vga_vs`、`vga_r/g/b` 是否持续变化。

## 3. 切换独立 testbench

如果只想验证 FIFO：

```tcl
set sim_top tb_async_fifo
source scripts/run_sim.tcl
```

如果只想验证 FFT 分析链：

```tcl
set sim_top tb_fft_chain
source scripts/run_sim.tcl
```

如果只想验证 VGA 渲染：

```tcl
set sim_top tb_vga_render
source scripts/run_sim.tcl
```

## 4. 各测试通过标准

### FIFO 测试

控制台应看到类似“通过：异步 FIFO 数据顺序和空满检查正确”的中文提示。若数据顺序错误、读空后 `empty` 不为高，testbench 会调用 `$fatal` 停止仿真。

### FFT 链测试

`tb_fft_chain` 使用 `freq_word = 32'h0800_0000`，对应 256 点 FFT 的第 8 个频点。通过标准是峰值频点接近 8，或者由于实信号频谱对称而接近 248。

### VGA 测试

`tb_vga_render` 会统计一帧有效像素数量。通过标准是有效像素数等于 `640 * 480`，并且渲染器产生了频谱柱或网格像素。

### 顶层测试

`tb_spec_analyzer_top` 会等待至少两个峰值有效脉冲。通过标准是峰值幅度非零，FIFO 状态不矛盾，系统链路没有死锁。

## 5. 生成 FFT IP

当前工程已经能使用行为级 FFT 模型进行课程仿真。如果老师要求展示 Vivado FFT IP 生成流程，可以执行：

```tcl
source scripts/gen_ip_fft.tcl
```

生成 IP 后，建议仍保留 `xfft_wrapper` 作为唯一修改点。这样报告中可以说明：系统其他模块不依赖具体 IP 版本，FFT IP 参数变化时只需要维护一个封装文件。

## 6. 报告截图建议

推荐截图顺序：

1. DDS 输出波形和 `sample_valid`；
2. FIFO 写入、读出和空满标志；
3. FFT 输入 `tvalid/tready/tlast`；
4. FFT 输出频点、幅度和峰值检测；
5. VGA 有效显示区、像素坐标和 RGB 输出。

这样截图顺序正好对应系统数据流，答辩时讲起来比较顺。
