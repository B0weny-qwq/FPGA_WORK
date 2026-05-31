# IP 接入说明

## 1. 总览

本工程的 IP 策略是“真实 FFT IP 主链路 + 展示型 IP 保留 + 手写 RTL 可解释”。这样既满足课程对 Vivado IP 的要求，又保留 DDS、FIFO、VGA 和后处理的答辩解释空间。

## 2. IP 清单

| IP 名称 | Vivado IP | XCI 路径 | 用途 | 接入状态 |
| --- | --- | --- | --- | --- |
| `xfft_256` | `xilinx.com:ip:xfft:9.1` | `ip/xfft_256_1/xfft_256.xci` | 256 点 FFT | 已在 `xfft_wrapper` 综合路径真实实例化 |
| `async_sample_fifo_ip` | `xilinx.com:ip:fifo_generator:13.2` | `ip/async_sample_fifo_ip/async_sample_fifo_ip.xci` | 异步 FIFO IP 展示 | 已导入工程；定义 `USE_ASYNC_SAMPLE_FIFO_IP` 时可选接入 |
| `sine_rom_256` | `xilinx.com:ip:blk_mem_gen:8.4` | `ip/sine_rom_256/sine_rom_256.xci` | 正弦查找表 IP 化展示 | 已导入工程，默认 RTL 仍使用 `wave_rom_sin` |
| `hann_rom_256` | `xilinx.com:ip:blk_mem_gen:8.4` | `ip/hann_rom_256/hann_rom_256.xci` | Hann 系数 ROM IP 化展示 | 已导入工程，默认 RTL 仍使用 `hann_rom` |
| `spec_bin_bram` | `xilinx.com:ip:blk_mem_gen:8.4` | `ip/spec_bin_bram/spec_bin_bram.xci` | 频谱缓存 BRAM 展示 | 已导入工程，默认 RTL 仍使用 `spec_bin_buffer` 内部数组 |

## 3. 生成脚本

执行：

```tcl
source scripts/gen_ip_all.tcl
```

脚本会优先查找已存在的 `.xci`，兼容 `ip/<module_name>/<module_name>.xci` 和 `ip/<module_name>_1/<module_name>.xci` 两种目录。如果 `.xci` 不存在，则调用 `create_ip` 生成。生成完成后写出 `reports/ip_status.md`。

旧入口 `scripts/gen_ip_fft.tcl` 仍保留，内部调用 `gen_ip_all.tcl`，避免已有教程命令失效。

## 4. FFT IP 接入点

`rtl/fft/xfft_wrapper.v` 是唯一 FFT IP 封装点。

仿真：

```verilog
`ifdef XFFT_BEHAVIORAL_DFT_SIM
```

打开时使用行为级 DFT，testbench 不依赖 Xilinx IP 仿真库即可完成频点自检。

综合：

```verilog
xfft_256 u_xfft_256 (...);
```

未定义 `XFFT_BEHAVIORAL_DFT_SIM` 时实例化真实 `xfft_256`。`fft_cfg_rom` 提供 16 位配置字，AXI-Stream 输入输出宽度均为 32 位，格式为 `{imag[15:0], real[15:0]}`。

## 5. FIFO IP 可选接入点

`rtl/fifo/async_fifo_bridge.v` 默认实例化手写 `async_fifo`：

```verilog
async_fifo u_async_fifo (...);
```

定义 `USE_ASYNC_SAMPLE_FIFO_IP` 时改为实例化：

```verilog
async_sample_fifo_ip u_async_sample_fifo_ip (...);
```

默认不启用 FIFO IP 的原因是：课程答辩中异步 FIFO 的 Gray 指针、空满判断和 CDC 同步是重要可解释设计点。IP 路径保留为展示和扩展入口。

## 6. ROM/BRAM 展示 IP

`sine_rom_256`、`hann_rom_256`、`spec_bin_bram` 目前作为工程识别和答辩展示 IP。默认数据通路仍使用手写 RTL，是为了保持仿真稳定和逻辑可读：

- `wave_rom_sin` 展示四分之一正弦表展开方法。
- `hann_rom` 展示半窗对称查表方法。
- `spec_bin_buffer` 展示双时钟读写显示缓存。

如果后续要把这些模块替换为 IP，只需要在对应 RTL 模块外加类似 `async_fifo_bridge` 的薄封装，不需要改动顶层数据流。
