# gen_ip_fft.tcl
# 兼容旧入口：只生成或导入 xfft_256。完整 IP 清单请使用 gen_ip_all.tcl。

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir gen_ip_all.tcl]
