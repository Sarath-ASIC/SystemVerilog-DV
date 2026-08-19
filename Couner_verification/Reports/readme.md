## Report from VCS after regression runs


# Verification Coverage & Quality Analysis Report

This document details the root causes behind the current verification metrics (Total Score: **85.78%**) obtained from the Synopsys VCS URG dashboard and outlines the necessary corrective actions to achieve 100% verification sign-off closure.

---

## 1. Metrics Scorecard & Gap Analysis

```text
=============================================================================================
Metric                   Achieved      Target     Status      Primary Bottleneck
=============================================================================================
Line Coverage             100.00%     100.00%     Passed      Fully Covered
Branch Coverage           100.00%     100.00%     Passed      Fully Covered
Toggle Coverage            97.73%     > 95.00%    Passed      Missing mid-run rst_n toggle
Functional Coverage        91.96%     100.00%     Attention   Walking-1s load bins missed
Assertion Coverage         75.00%     100.00%     Attention   Unexercised reset/rollover SVA
Condition Coverage         50.00%     100.00%     Attention   TB-level ternary expressions
=============================================================================================
