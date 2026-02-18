# Makefile

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
EXTRA_ARGS += --trace --trace-structs
COMPILE_ARGS += -DSIMULATION
WAVES = 1

VERILOG_SOURCES += $(PWD)/../../src/rgmii_rx.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = rgmii_rx

# MODULE is the basename of the Python test file
MODULE = test_rgmii_rx
export SIMULATION = 1

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim