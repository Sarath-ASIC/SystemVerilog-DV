# 8-Bit Synchronous Up/Down Counter with Verification Suite

A SystemVerilog design and verification suite for a parameterized, synchronous 8-bit bidirectional counter with parallel load, count-enable control, and single-cycle rollover pulse generation. The verification environment leverages Assertion-Based Verification (ABV) and functional covergroups executed with Synopsys VCS and analyzed via URG/Verdi.

---

## 1. Architectural Specification
+--------------------------+
clk ---------->|                          |
rst_n -------->|                          |
en ----------->|       counter_8bit       |---> count [7:0]
load --------->|                          |---> rollover
up_down ------>|                          |
load_val [7:0]->|                         |
+--------------------------+
