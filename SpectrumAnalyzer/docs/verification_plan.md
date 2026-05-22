# 验证计划

## 静态检查目标

- 检查 README 中要求的目录和文件是否全部存在；
- 检查 RTL 文件名和模块名是否一致；
- 检查每个 Verilog/SystemVerilog 文件是否只有一个顶层模块定义；
- 检查顶层是否连接完整链路：DDS、窗口、FIFO、FFT 帧控制、FFT 封装、幅度计算、峰值检测、频谱缓存和 VGA；
- 检查 testbench 是否包含复位、激励、结束条件和自检查。

## Testbench 说明

### `tb_async_fifo`

验证目标：独立验证异步 FIFO。

检查内容：

- 写入一组连续数据时不应误报 `full`；
- 读出数据顺序必须与写入顺序一致；
- 全部读出后 `empty` 应为高；
- 只有 `rd_valid` 为高时才检查读数据。

### `tb_fft_chain`

验证目标：验证 DDS 到 FFT 后处理链路。

检查内容：

- 使用 `freq_word = 32'h0800_0000` 产生单音正弦；
- 对 256 点 FFT 来说，主峰应接近第 8 个频点，或接近镜像频点 248；
- FFT 输入 `tlast` 相关事件标志不应报错。

### `tb_vga_render`

验证目标：独立验证 VGA 时序和频谱渲染。

检查内容：

- 一帧有效像素数量应为 `640 * 480`；
- 频谱渲染器应产生至少一个柱状图或网格像素。

### `tb_spec_analyzer_top`

验证目标：验证系统顶层端到端链路。

检查内容：

- 等待至少两个 `debug_peak_valid` 脉冲；
- 峰值幅度不能一直为 0；
- FIFO 不应同时报告 `full` 和 `empty`。

## 波形截图清单

建议保存以下信号作为课程报告证据：

- `sample_data`、`sample_valid`、`wave_sel`、`freq_word`；
- `fifo_full`、`fifo_empty`、`fifo_rd_valid`；
- `fft_s_axis_tvalid`、`fft_s_axis_tready`、`fft_s_axis_tlast`；
- `fft_tvalid`、`fft_tlast`、`mag_valid`；
- `peak_bin`、`peak_mag`、`peak_valid`；
- `vga_hs`、`vga_vs`、`active_video`、`pixel_x`、`pixel_y`、RGB。

## 仿真边界说明

当前 `xfft_wrapper` 内部是行为级 DFT 仿真模型，目的是让工程在没有 Vivado FFT IP 文件的情况下也能说明完整链路。若需要接入真实 FFT IP，请先运行 `scripts/gen_ip_fft.tcl`，再只修改 `rtl/fft/xfft_wrapper.v`，其他模块接口保持不变。
