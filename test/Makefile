# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

.DEFAULT_GOAL := sim

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = \
    project.v \
    control_unit.v \
    instruction_register.v \
    memory.v \
    program_counter.v \
    prometheus_lite.v \
    register_file.v

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/gf180mcu_fd_sc_mcu7t5v0.v

# this gets copied in by the GDS action workflow
GATE_NETLIST ?= $(PWD)/gate_level_netlist.v
VERILOG_SOURCES += $(GATE_NETLIST)
SRAM_CELL = gf180mcu_ocd_ip_sram__sram1024x8m8wm1
SRAM_MODEL = $(PWD)/../build/asic-memory/ocd/cells/$(SRAM_CELL)/$(SRAM_CELL).v
SRAM_SIM_MODEL = $(abspath $(SIM_BUILD))/$(SRAM_CELL).v
VERILOG_SOURCES += $(SRAM_SIM_MODEL)

$(SRAM_SIM_MODEL): $(SRAM_MODEL) sram-sim.patch
	mkdir -p $(@D)
	patch --batch --fuzz=0 -o $@ $< sram-sim.patch

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

ifeq ($(GATES),yes)
COCOTB_TEST_MODULES = test_gl
else
COCOTB_TEST_MODULES = test
endif

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
