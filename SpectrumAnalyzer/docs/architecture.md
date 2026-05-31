# 系统架构说明

## 1. 总体结构

本工程实现一个课程答辩用 FPGA 频谱分析仪。系统使用内部 DDS 产生测试信号，不依赖外部 ADC；综合路径真实接入 Vivado `xfft_256` FFT IP；显示端使用 VGA 风格时序输出频谱柱状图和 OSD 文字。

```text
DDS 信号源
  -> 可选 Hann 窗
  -> async_fifo_bridge / async_fifo
  -> fft_frame_ctrl
  -> xfft_wrapper / xfft_256
  -> fft_mag_calc
  -> peak_detector
  -> mag_compress / spec_bin_buffer
  -> vga_timing_gen / spectrum_renderer / osd_text_gen / overlay_mux
```

其中 `async_fifo_bridge` 默认实例化手写 `async_fifo`，便于展示 Gray 指针、空满判断和跨时钟域同步；如定义 `USE_ASYNC_SAMPLE_FIFO_IP`，可切换到 Vivado FIFO Generator IP。这个桥接层保持外部接口不变，是最小侵入式的 IP 展示入口。

## 2. 时钟域划分

| 时钟域 | 推荐频率 | 主要模块 | 作用 |
| --- | ---: | --- | --- |
| `clk_sample` | 10 MHz | DDS、Hann 窗、FIFO 写侧 | 产生并预处理有符号采样数据 |
| `clk_fft` | 50 MHz | FIFO 读侧、FFT、后处理 | 组成 256 点帧并完成频谱分析 |
| `clk_pixel` | 25 MHz | VGA 时序、渲染、叠加 | 产生 640x480 风格像素流 |

`clk_rst_gen` 为三个时钟域分别生成同步释放复位。样本域到 FFT 域之间通过异步 FIFO 隔离，默认 RTL FIFO 内部使用 Gray 编码指针和两级同步器。

## 3. 数据流说明

1. `dds_signal_gen` 根据 `wave_sel` 和 `freq_word` 产生正弦、方波、三角波、锯齿波或双音样本。
2. `win_mul_optional` 在 `window_en=1` 时读取 256 点 Hann 系数并进行 Q1.15 定点乘法，关闭时旁路。
3. `async_fifo_bridge` 把样本从 `clk_sample` 域送到 `clk_fft` 域，默认使用手写 `async_fifo`。
4. `fft_frame_ctrl` 每帧凑够 256 点，按 `{imag[15:0], real[15:0]}` 打包输入 AXI-Stream，并在最后一点产生 `tlast`。
5. `xfft_wrapper` 是 FFT IP 的唯一隔离层。仿真宏 `XFFT_BEHAVIORAL_DFT_SIM` 打开时使用行为级 DFT；综合路径实例化 `xfft_256`。
6. `fft_mag_calc` 解包复数频域数据，计算 `real*real + imag*imag`。
7. `peak_detector` 忽略直流频点，锁存当前帧最大频点和幅度。
8. `mag_compress` 将 32 位幅度压缩为 8 位显示高度。
9. `spec_bin_buffer` 保存前 128 个可视频点，供像素时钟域读取。
10. `vga_timing_gen`、`spectrum_renderer`、`osd_text_gen`、`overlay_mux` 生成最终 RGB/HS/VS 输出。

## 4. 手写 RTL 与 IP 分工

| 类别 | 模块 |
| --- | --- |
| 手写 RTL 核心 | DDS、Hann 窗、默认异步 FIFO、FFT 帧控制、幅度计算、峰值检测、压缩、频谱缓存、VGA |
| 真实综合 IP | `xfft_256`，在 `xfft_wrapper` 综合路径中实例化 |
| 可选/展示 IP | `async_sample_fifo_ip`、`sine_rom_256`、`hann_rom_256`、`spec_bin_bram` |

这样保留了课程可解释性：老师可以看到 DDS/FIFO/VGA/后处理的 RTL 设计，也能在工程和综合网表中看到真实 FFT IP。

## 5. 电路图讲解顺序

打开 elaborated design 或 synthesized design 后，从 `spec_analyzer_top` 按以下顺序展开：

```text
u_dds_signal_gen
u_win_mul_optional
u_async_fifo_bridge / u_async_fifo
u_fft_frame_ctrl
u_xfft_wrapper / u_xfft_256
u_fft_mag_calc
u_peak_detector
u_mag_compress
u_spec_bin_buffer
u_vga_timing_gen
u_spectrum_renderer
u_osd_text_gen
u_overlay_mux
```

综合脚本使用 `flatten_hierarchy none`，目的是保留这些层级，方便答辩时沿数据流解释每个模块的职责。
