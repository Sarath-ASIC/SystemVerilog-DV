# 8-Bit Synchronous Up/Down Counter with Verification Suite

A SystemVerilog design and verification suite for a parameterized, synchronous 8-bit bidirectional counter with parallel load, count-enable control, and single-cycle rollover pulse generation. The verification environment leverages Assertion-Based Verification (ABV) and functional covergroups executed with Synopsys VCS and analyzed via URG/Verdi.

---

## 1. Architectural Specification
![Counter Flow Diagram](<Couner_verification/Flow-Diagram/Counter_8bit.drawio (1).png>)

### Signal Definitions & Priority Rules
* **`rst_n` (Active-Low Synchronous Reset)**: Clears `count` to `8'h00` and `rollover` to `0` on the rising clock edge. Has the highest priority.
* **`load` (Synchronous Parallel Load)**: Overrides counting and directly updates `count` with `load_val`. Takes priority over `en`.
* **`en` (Count Enable)**: When high (and `load` is low), increments or decrements the counter based on `up_down`. When low, preserves the current state.
* **`up_down` (Direction Control)**: `1` = Increment, `0` = Decrement.
* **`rollover` (Terminal Pulse)**: Asserted for strictly 1 cycle when the counter rolls over (`0xFF -> 0x00` in up-mode, `0x00 -> 0xFF` in down-mode).

---

## 2. Verification Plan (VPlan)

### 2.1 Feature Matrix

| Feature ID | Feature Name | Description | Verification Method |
| :--- | :--- | :--- | :--- |
| **FEAT-01** | Synchronous Reset | Forces `count` to `8'h00` and clears `rollover` on `posedge clk` when `rst_n == 0`. | SVA (`a_sync_reset`), Directed TB |
| **FEAT-02** | Parallel Load | Loads `load_val` directly into `count` when `load == 1`, overriding `en`. | SVA (`a_load_priority`), Random Stimulus |
| **FEAT-03** | Up-Counting | Increments `count` by 1 per cycle when `en == 1` and `up_down == 1`. | SVA (`a_count_up`), Functional Coverage |
| **FEAT-04** | Down-Counting | Decrements `count` by 1 per cycle when `en == 1` and `up_down == 0`. | SVA (`a_count_down`), Functional Coverage |
| **FEAT-05** | Inactive Hold | Retains current `count` value unchanged when `en == 0` and `load == 0`. | SVA (`a_hold_disabled`), Functional Coverage |
| **FEAT-06** | Up Rollover | Detects `8'hFF -> 8'h00` transition, sets `count = 8'h00`, asserts `rollover` for exactly 1 cycle. | SVA (`a_rollover_up`, `a_rollover_one_cycle`), Directed TB |
| **FEAT-07** | Down Rollover | Detects `8'h00 -> 8'hFF` transition, sets `count = 8'hFF`, asserts `rollover` for exactly 1 cycle. | SVA (`a_rollover_down`, `a_rollover_one_cycle`), Directed TB |

### 2.2 Coverage Strategy
* **Coverpoints**:
  * Control inputs: `en`, `load`, `up_down`.
  * Data inputs: `load_val` corner cases (`0x00`, `0xFF`), walking-1s (`0x01`, `0x02`, ..., `0x80`), and mid-range partitions.
  * State tracking: `count` full-range coverage (`0` to `255`) and boundary transitions (`0xFF => 0x00`, `0x00 => 0xFF`).
  * Flags: `rollover` trigger and idle states.
* **Cross Coverage**:
  * Cross of `en` × `up_down` × `load` to verify all 8 operation modes.
  * Cross of `rollover` × `up_down` × `en` to ensure overflow/underflow happens exclusively in active counting states.

### 2.3 Sign-Off Targets
* 100% Line & Branch Coverage on the RTL DUT.
* > 95% Toggle Coverage.
* > 90% Functional Group Coverage.
* 100% SVA Pass Rate (0 failures).
