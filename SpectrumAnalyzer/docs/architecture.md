# 系统架构说明

## 总体结构

本课程设计实现一个仿真用 FPGA 频谱分析仪，数据链路严格采用：

```text
DDS 信号源 -> 可选 Hann 窗 -> 异步 FIFO -> FFT 帧控制 -> FFT 封装
           -> 幅度计算/峰值检测 -> 频谱缓存 -> VGA 渲染
```

系统使用内部 DDS 产生测试信号，不依赖外部 ADC。`rtl/fft/xfft_wrapper.v` 是 FFT IP 的唯一隔离层，当前提供行为级 DFT 仿真模型；如果后续换成 Vivado FFT IP，只需要修改该封装文件。

## 时钟域划分

| 时钟域 | 推荐频率 | 主要模块 | 作用 |
| --- | ---: | --- | --- |
| `clk_sample` | 10 MHz | DDS、窗口、FIFO 写侧 | 产生有符号采样数据 |
| `clk_fft` | 50 MHz | FIFO 读侧、FFT、后处理 | 完成频谱分析 |
| `clk_pixel` | 25 MHz | VGA 时序、渲染、叠加 | 产生显示像素流 |

`clk_rst_gen` 为三个时钟域分别生成同步释放的低有效复位。样本域到 FFT 域之间通过 `async_fifo` 隔离，FIFO 内部使用 Gray 编码指针和两级同步器降低跨时钟域风险。

## 数据流说明

1. `ctrl_model` 在仿真中按固定时间切换波形、频率、双音和窗口状态。
2. `dds_signal_gen` 产生正弦波、方波、三角波或锯齿波，输出 16 位有符号样本。
3. `win_mul_optional` 在窗口关闭时旁路样本，在窗口开启时乘以 256 点 Hann 系数。
4. `async_fifo` 将样本从 `clk_sample` 域送入 `clk_fft` 域。
5. `fft_frame_ctrl` 每帧读取 256 个有效样本，按 `{imag[15:0], real[15:0]}` 打包输入 FFT。
6. `xfft_wrapper` 输出同样格式的复数频域数据。
7. `fft_mag_calc` 计算功率幅度 `real*real + imag*imag`。
8. `peak_detector` 在一帧结束时锁存最大非直流频点。
9. `mag_compress` 将 32 位幅度压缩成 8 位显示等级。
10. `spec_bin_buffer` 保存前 128 个可视频点。
11. `vga_timing_gen`、`spectrum_renderer`、`osd_text_gen` 和 `overlay_mux` 生成 VGA 风格输出。

## 关键设计点

- DDS 使用相位累加器，频率控制字越大，输出波形周期越短。
- FIFO 空满判断使用额外一位指针，满判断采用写指针下一值与读指针同步值高两位取反比较。
- FFT 帧控制只在 `tready` 有效且 FIFO 非空时读样本，最后一个样本产生 `tlast`。
- 幅度计算使用有符号实部/虚部平方后相加，避免复数符号解析错误。
- VGA 层叠优先级固定为：OSD 文字最高，频谱柱状图次之，背景最低。

## 报告展示建议

建议在报告和答辩中截取以下波形：

- DDS：`sample_valid`、`sample_data`、`debug_phase_word`；
- FIFO：`full`、`empty`、`rd_valid`、`debug_wr_level`、`debug_rd_level`；
- FFT 输入：`fft_s_axis_tvalid`、`fft_s_axis_tready`、`fft_s_axis_tlast`；
- FFT 输出：`m_axis_tvalid`、`m_axis_tlast`、`debug_out_bin`；
- 后处理：`mag_valid`、`mag_bin`、`peak_bin`、`peak_valid`；
- 显示：`active_video`、`pixel_x`、`pixel_y`、RGB 输出。
