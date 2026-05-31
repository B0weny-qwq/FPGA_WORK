# 接口说明

## 1. 顶层模块 `spec_analyzer_top`

| 信号 | 方向 | 位宽 | 时钟域 | 含义 |
| --- | --- | ---: | --- | --- |
| `clk_sample` | 输入 | 1 | 样本域 | DDS、Hann 窗、FIFO 写侧时钟 |
| `clk_fft` | 输入 | 1 | FFT 域 | FIFO 读侧、FFT、后处理时钟 |
| `clk_pixel` | 输入 | 1 | 像素域 | VGA 像素时钟 |
| `rst_n` | 输入 | 1 | 异步输入 | 外部低有效复位 |
| `wave_sel` | 输入 | 2 | 样本域 | 0 正弦，1 方波，2 三角波，3 锯齿波 |
| `freq_word` | 输入 | 32 | 样本域 | DDS 频率控制字 |
| `dual_tone_en` | 输入 | 1 | 样本域 | 双音测试模式使能 |
| `window_en` | 输入 | 1 | 样本域 | Hann 窗使能 |
| `vga_hs`、`vga_vs` | 输出 | 1 | 像素域 | VGA 行/场同步 |
| `vga_r/g/b` | 输出 | 各 4 | 像素域 | RGB444 像素输出 |
| `debug_peak_bin` | 输出 | 8 | FFT 域 | 当前帧峰值频点 |
| `debug_peak_mag` | 输出 | 32 | FFT 域 | 当前帧峰值幅度 |
| `debug_peak_valid` | 输出 | 1 | FFT 域 | 峰值结果有效脉冲 |
| `debug_fifo_full/empty` | 输出 | 1 | FIFO 两侧 | FIFO 状态 |
| `debug_fft_bin` | 输出 | 8 | FFT 域 | FFT 输出频点编号 |

## 2. DDS 与 Hann 窗接口

`dds_signal_gen` 输出 16 位有符号样本和 `sample_valid`。正弦波由 `wave_rom_sin` 查表得到，方波、三角波、锯齿波由相位字组合生成。双音模式会把第二路正弦与主波形平均相加，避免溢出。

`win_mul_optional` 接收 DDS 样本流：

| 信号 | 方向 | 含义 |
| --- | --- | --- |
| `window_en` | 输入 | 1 为 Hann 加窗，0 为旁路 |
| `sample_in/sample_in_valid` | 输入 | DDS 输出样本流 |
| `sample_out/sample_out_valid` | 输出 | 加窗后或旁路后的样本流 |
| `debug_coeff_addr` | 输出 | 当前 Hann 系数地址 |

Hann 系数为无符号 Q1.15，乘法后右移 15 位恢复到 16 位有符号样本。

## 3. FIFO 接口

顶层实例化 `async_fifo_bridge`：

| 信号 | 方向 | 时钟域 | 含义 |
| --- | --- | --- | --- |
| `wr_en/wr_data` | 输入 | `clk_wr` | 写请求和写入样本 |
| `rd_en` | 输入 | `clk_rd` | 读请求 |
| `rd_data/rd_valid` | 输出 | `clk_rd` | 读出样本和有效标志 |
| `full` | 输出 | 写侧 | 写侧满标志 |
| `empty` | 输出 | 读侧 | 读侧空标志 |
| `debug_wr_level/debug_rd_level` | 输出 | 对应侧 | 调试用深度估计 |

默认路径实例化手写 `async_fifo`。可选定义 `USE_ASYNC_SAMPLE_FIFO_IP` 后，桥接层实例化 `async_sample_fifo_ip`，连接 Vivado FIFO Generator 的 `rst/wr_clk/rd_clk/din/wr_en/rd_en/dout/full/empty/valid/wr_rst_busy/rd_rst_busy` 端口。

## 4. FFT AXI-Stream 接口

### `fft_frame_ctrl`

`fft_frame_ctrl` 从 FIFO 读取有效样本，并输出 FFT 输入 AXI-Stream：

```text
fft_s_axis_tdata  = {16'd0, fifo_rd_data}
fft_s_axis_tvalid = 当前样本有效
fft_s_axis_tlast  = 256 点帧的最后一点
```

### `xfft_wrapper`

`xfft_wrapper` 对外固定使用 32 位复数格式：

```text
{imag[15:0], real[15:0]}
```

仿真模式：

- 定义 `XFFT_BEHAVIORAL_DFT_SIM`。
- 使用行为级 DFT，方便快速自检。

综合模式：

- 不定义 `XFFT_BEHAVIORAL_DFT_SIM`。
- 实例化 Vivado `xfft_256`。
- 配置通道由 `fft_cfg_rom` 给出 16 位配置字，当前 bit0 置 1，表示正向 FFT。

## 5. 后处理接口

| 模块 | 输入 | 输出 | 说明 |
| --- | --- | --- | --- |
| `fft_mag_calc` | FFT `tdata/tvalid/tlast` | `mag_data/mag_bin/mag_valid/mag_frame_done` | 计算 `real*real + imag*imag` |
| `peak_detector` | 幅度流 | `peak_bin/peak_mag/peak_valid` | 忽略 DC，帧末锁存最大频点 |
| `mag_compress` | 32 位幅度 | 8 位显示高度 | 分段移位压缩并限幅 |
| `spec_bin_buffer` | 压缩频点流 | VGA 读出的 `rd_level` | 只缓存前 128 个可视频点 |

## 6. VGA 接口

`vga_timing_gen` 使用 640x480 风格时序：

| 项目 | 水平 | 垂直 |
| --- | ---: | ---: |
| 有效区 | 640 | 480 |
| 前肩 | 16 | 10 |
| 同步脉冲 | 96 | 2 |
| 后肩 | 48 | 33 |

`spectrum_renderer` 根据 `bin_rd_addr` 读取频点高度并绘制柱状图。`osd_text_gen` 生成状态文字。`overlay_mux` 的优先级为：OSD 文字最高，频谱柱状图其次，背景最低。
