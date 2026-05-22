# 接口说明

## 顶层模块 `spec_analyzer_top`

| 信号 | 方向 | 位宽 | 时钟域 | 含义 |
| --- | --- | ---: | --- | --- |
| `clk_sample` | 输入 | 1 | 样本域 | DDS 和 FIFO 写侧时钟 |
| `clk_fft` | 输入 | 1 | FFT 域 | FIFO 读侧、FFT、后处理时钟 |
| `clk_pixel` | 输入 | 1 | 像素域 | VGA 像素时钟 |
| `rst_n` | 输入 | 1 | 异步输入 | 外部低有效复位 |
| `wave_sel` | 输入 | 2 | 样本域 | 0 正弦，1 方波，2 三角波，3 锯齿波 |
| `freq_word` | 输入 | 32 | 样本域 | DDS 频率控制字 |
| `dual_tone_en` | 输入 | 1 | 样本域 | 双音模式使能 |
| `window_en` | 输入 | 1 | 样本域 | Hann 窗使能 |
| `vga_hs`、`vga_vs` | 输出 | 1 | 像素域 | VGA 行/场同步 |
| `vga_r/g/b` | 输出 | 各 4 | 像素域 | RGB444 像素输出 |
| `debug_peak_bin` | 输出 | 8 | FFT 域 | 当前帧峰值频点 |
| `debug_peak_mag` | 输出 | 32 | FFT 域 | 当前帧峰值幅度 |
| `debug_peak_valid` | 输出 | 1 | FFT 域 | 峰值结果有效脉冲 |
| `debug_fifo_full/empty` | 输出 | 1 | 混合 | FIFO 状态 |
| `debug_fft_bin` | 输出 | 8 | FFT 域 | FFT 输出频点编号 |

## DDS 与窗口模块

### `phase_acc`

在 `phase_en` 为高时，每个 `clk_sample` 周期累加 `freq_word`。输出相位为内部累加值加上 `phase_offset`，自然溢出表示相位回绕。

### `dds_signal_gen`

输出 16 位有符号样本和固定节拍的 `sample_valid`。正弦波来自查找表，方波、三角波和锯齿波由相位字组合生成。双音模式下，第二路正弦和主波形相加后右移一位，避免溢出。

### `win_mul_optional`

窗口关闭时直接输出输入样本。窗口开启时读取 Q1.15 Hann 系数，与样本相乘后右移 15 位恢复到 16 位有符号数据。

## FIFO 模块

### `async_fifo`

| 信号 | 方向 | 时钟域 | 含义 |
| --- | --- | --- | --- |
| `wr_en`、`wr_data` | 输入 | `clk_wr` | 写请求和写入样本 |
| `full` | 输出 | `clk_wr` | 写侧满标志 |
| `rd_en` | 输入 | `clk_rd` | 读请求 |
| `rd_data`、`rd_valid` | 输出 | `clk_rd` | 注册读数据和有效标志 |
| `empty` | 输出 | `clk_rd` | 读侧空标志 |

FIFO 使用 `ADDR_WIDTH + 1` 位读写指针。二进制指针用于地址和深度估计，Gray 指针用于跨时钟域同步和空满比较。

## FFT 链路

### `fft_frame_ctrl`

当 FIFO 非空且 FFT 输入 ready 时发出读请求。接收到 `fifo_rd_valid` 后打包一个 FFT 输入样本。每帧正好 256 个样本，最后一个样本置位 `fft_s_axis_tlast`。

### `xfft_wrapper`

FFT 输入和输出数据统一采用：

```text
{imag[15:0], real[15:0]}
```

`s_axis_tready` 表示可接收输入样本。`m_axis_tvalid` 表示输出频点有效，`m_axis_tlast` 表示一帧最后一个频点。

## 后处理模块

### `fft_mag_calc`

将 FFT 输出拆成有符号实部和虚部，计算：

```text
magnitude = real * real + imag * imag
```

输出包括幅度值、频点编号、有效标志和帧结束标志。

### `peak_detector`

每帧从非直流频点中查找最大幅度。帧结束时锁存 `peak_bin` 和 `peak_mag`，并产生一个周期的 `peak_valid`。

### `mag_compress`

用分段移位方式把 32 位幅度压缩为 8 位显示等级，并限制在最大显示高度范围内。

### `spec_bin_buffer`

在 `clk_fft` 域写入压缩后的频点等级，在 `clk_pixel` 域按照 VGA 渲染器给出的地址读取。当前只显示前 128 个频点。

## VGA 模块

### `vga_timing_gen`

使用 640x480 仿真时序：

| 项目 | 水平 | 垂直 |
| --- | ---: | ---: |
| 有效区 | 640 | 480 |
| 前肩 | 16 | 10 |
| 同步脉冲 | 96 | 2 |
| 后肩 | 48 | 33 |

### `spectrum_renderer`

将绘图区横向映射到 128 个频点，根据 `bin_level` 计算柱状图高度并输出频谱图层 RGB。

### `osd_text_gen`

显示一行状态文字，包括波形类型、FFT 点数、峰值频点和窗口状态。

### `overlay_mux`

合成背景、频谱和 OSD 图层。有效显示区外输出黑色，图层优先级固定，便于仿真观察。
