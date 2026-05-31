# Synthesis Check Summary

- Top: `spec_analyzer_top`
- Strategy: `flatten_hierarchy none`, keeping the main hierarchy readable for schematic review.
- FFT: `xfft_wrapper` instantiates real `xfft_256` IP when `XFFT_BEHAVIORAL_DFT_SIM` is not defined.
- Reports: `synth_utilization.rpt`, `timing_summary.rpt`, `hierarchy.rpt`, `compile_order.rpt`.
