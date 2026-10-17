# Vibecoded makefile

IVERILOG := iverilog
VVP := vvp

BUILD_DIR := build

# Automatically discover RTL and testbenches
RTL := $(wildcard *.v)
TESTS := $(wildcard tests/*_testbench.v)

.PHONY: all test clean list

all: test

test:
	@mkdir -p $(BUILD_DIR)
	@set -e; \
	passed=0; \
	failed=0; \
	for tb in $(TESTS); do \
		name=$$(basename $$tb .v); \
		echo "================================"; \
		echo "Testing: $$name"; \
		echo "================================"; \
		if $(IVERILOG) -g2012 -Wall -s $$name \
			-o $(BUILD_DIR)/$$name $(RTL) $$tb && \
		   $(VVP) $(BUILD_DIR)/$$name; then \
			echo "[PASS] $$name"; \
			passed=$$((passed + 1)); \
		else \
			echo "[FAIL] $$name"; \
			failed=$$((failed + 1)); \
		fi; \
		echo; \
	done; \
	echo "================================"; \
	echo "Results: $$passed passed, $$failed failed"; \
	echo "================================"; \
	test $$failed -eq 0

list:
	@echo "RTL modules: $(RTL)"
	@echo "Testbenches: $(TESTS)"

clean:
	rm -rf $(BUILD_DIR)
