# Graph Report - SpectrumAnalyzer  (2026-05-31)

## Corpus Check
- 66 files · ~187,218 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 178 nodes · 114 edges · 67 communities (63 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `25db1e34`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]

## God Nodes (most connected - your core abstractions)
1. `SpectrumAnalyzer 满分级补齐 Goal` - 16 edges
2. `接口说明` - 13 edges
3. `中文测试教程` - 12 edges
4. `系统架构说明` - 11 edges
5. `验证计划` - 11 edges
6. `FPGA 频谱分析仪课程设计` - 8 edges
7. `IP 接入说明` - 7 edges
8. `综合电路图说明` - 6 edges
9. `4. 各测试通过标准` - 5 edges
10. `后处理模块` - 5 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (67 total, 4 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.12
Nodes (15): 1. 验证目标, 2. 静态检查, 3. Testbench, 4. 综合检查, 5. IP 状态检查, 6. 电路图验收, `tb_async_fifo`, `tb_fft_chain` (+7 more)

### Community 1 - "Community 1"
Cohesion: 0.09
Nodes (22): 1. 顶层模块 `spec_analyzer_top`, 2. DDS 与 Hann 窗接口, 3. FIFO 接口, 4. FFT AXI-Stream 接口, 5. 后处理接口, 6. VGA 接口, `async_fifo`, `dds_signal_gen` (+14 more)

### Community 2 - "Community 2"
Cohesion: 0.17
Nodes (11): 1. 总体结构, 2. 时钟域划分, 3. 数据流说明, 4. 手写 RTL 与 IP 分工, 5. 电路图讲解顺序, 关键设计点, 总体结构, 报告展示建议 (+3 more)

### Community 3 - "Community 3"
Cohesion: 0.11
Nodes (17): 1. 创建 Vivado 工程, 1. 创建完整 Vivado 工程, 2. 批量运行 4 个 testbench, 2. 运行顶层仿真, 3. 切换独立 testbench, 3. 单独运行某个 testbench, 4. 各测试通过标准, 5.1 旧工程 source 缺失修复 (+9 more)

### Community 4 - "Community 4"
Cohesion: 0.40
Nodes (5): `fft_mag_calc`, `mag_compress`, `peak_detector`, `spec_bin_buffer`, 后处理模块

### Community 6 - "Community 6"
Cohesion: 0.12
Nodes (16): 0. 使用方式, 10. 边界与注意事项, 11. 当前已知状态提示, 12. 2026-05-31 本轮实现状态, 13. 2026-05-31 Boweny 工程 source/IP 缺失修复, 13. 2026-05-31 Synthesis source 缺失修复, 1. 总目标, 2. 最终系统链路 (+8 more)

### Community 7 - "Community 7"
Cohesion: 0.25
Nodes (7): 1. 总览, 2. IP 清单, 3. 生成脚本, 4. FFT IP 接入点, 5. FIFO IP 可选接入点, 6. ROM/BRAM 展示 IP, IP 接入说明

### Community 46 - "Community 46"
Cohesion: 0.22
Nodes (8): 1. 项目简介, 2. 当前验收状态, 3. 一键流程, 4. 脚本说明, 5. IP 状态, 6. 工程目录, 7. 文档入口, FPGA 频谱分析仪课程设计

### Community 47 - "Community 47"
Cohesion: 0.29
Nodes (6): 1. 验收目标, 2. 生成综合结果, 3. Vivado GUI 查看步骤, 4. 答辩讲解口径, 5. IP 与 RTL 标注, 综合电路图说明

## Knowledge Gaps
- **93 isolated node(s):** `1. 项目简介`, `2. 当前验收状态`, `3. 一键流程`, `4. 脚本说明`, `5. IP 状态` (+88 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `接口说明` connect `Community 1` to `Community 4`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **What connects `1. 项目简介`, `2. 当前验收状态`, `3. 一键流程` to the rest of the system?**
  _93 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.09486166007905138 - nodes in this community are weakly interconnected._
- **Should `Community 3` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Should `Community 6` be split into smaller, more focused modules?**
  _Cohesion score 0.11764705882352941 - nodes in this community are weakly interconnected._