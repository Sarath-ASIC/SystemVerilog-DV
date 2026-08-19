# 1. Compile with code coverage and SVA tracking enabled
vcs -sverilog -full64 -timescale=1ns/1ps -kdb -debug_access+all \
    -cm line+cond+fsm+tgl+branch+assert \
    -assert svaext -assert enable_diag \
    counter.sv assertion.sv coverage.sv counter_tb.sv \
    -o simv

# 2. Run simulation
./simv -cm line+cond+fsm+tgl+branch+assert -cm_name counter_test

# 3 Generate text & HTML reports
urg -dir simv.vdb -format both -report urgReport

# 4 View HTML dashboard in browser
firefox urgReport/dashboard.html &

# 5  Or inspect interactively via Verdi Coverage GUI
verdi -cov -covdir simv.vdb &
