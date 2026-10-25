# No longer vibecoded makefile
BUILD_DIRECTORY := build

# Get all our verilog code
CODE := $(wildcard src/*.v)
TEST := src/tests/prometheus_lite_testbench.v
TEST_OUTPUT := $(BUILD_DIRECTORY)/verilog/prometheus_lite_testbench

.PHONY: all test clean program

all: test # All can do the same thing

test: $(TEST_OUTPUT) # Make sure the build exists
	vvp $(TEST_OUTPUT)

$(TEST_OUTPUT): $(CODE) $(TEST) # Make sure we have code and the test
	mkdir -p $(@D) # Make the build directory if we need to 
	iverilog -g2012 -Wall \
		-s prometheus_lite_testbench \
		-o $(TEST_OUTPUT) $(CODE) $(TEST)

PROGRAM_TEST := src/tests/run_program.v
PROGRAM_OUTPUT := $(BUILD_DIRECTORY)/verilog/run_program

program:
	mkdir -p $(BUILD_DIRECTORY)/programs
	mkdir -p $(BUILD_DIRECTORY)/verilog
	python assembler/assembler.py $(FILE) $(BUILD_DIRECTORY)/programs/program.bin
	iverilog -g2012 -Wall \
		-s run_program \
		-o $(PROGRAM_OUTPUT) $(CODE) $(PROGRAM_TEST)
	vvp $(PROGRAM_OUTPUT)
clean:
	rm -rf $(BUILD_DIRECTORY)
	rm assembler/hex_program.bin


