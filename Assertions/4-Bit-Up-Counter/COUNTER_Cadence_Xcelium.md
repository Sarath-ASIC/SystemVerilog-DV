# SystemVerilog Counter Verification using Cadence Xcelium

## 1. Overview

This experiment demonstrates a complete SystemVerilog RTL simulation and assertion-based verification flow using Cadence Xcelium.

A parameterized 4-bit counter is verified using a SystemVerilog testbench containing three concurrent SystemVerilog Assertions (SVA):

1. Reset behavior
2. Counter hold behavior when enable is low
3. Counter increment behavior when enable is high

The simulation is executed using Cadence Xcelium 23.09-s007. A VCD waveform is generated and viewed using Cadence SimVision.

---

## 2. Objectives

The objectives of this experiment are:

- Run a SystemVerilog RTL design using Cadence Xcelium.
- Compile RTL and testbench files using `xrun`.
- Elaborate the design hierarchy.
- Verify RTL behavior using SystemVerilog Assertions.
- Generate a VCD waveform.
- View simulation waveforms using Cadence SimVision.
- Understand the Xcelium compilation, elaboration and simulation flow.
- Understand how assertions are evaluated during RTL simulation.

---

## 3. Tools and Environment

| Item | Details |
|---|---|
| Simulator | Cadence Xcelium |
| Xcelium Version | 23.09-s007 |
| HDL | SystemVerilog |
| Waveform Viewer | Cadence SimVision ||
| Timescale | 1ns/1ps |

Xcelium version was checked using:

```bash
xrun -version
