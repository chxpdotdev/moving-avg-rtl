# ==== Paths ====
BUILD_DIR := build
SRC       := $(wildcard src/*.v)
TB        ?= tb/tb_sliding_window.v
TOP       ?= tb_sliding_window

# ==== Tools ====
IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave

IVERILOG_FLAGS ?= -g2012 -Wall -I src -I tb

# ==== Outputs ====
SIMV := $(BUILD_DIR)/simv
VCD  := $(BUILD_DIR)/wave.vcd
FST  := $(BUILD_DIR)/wave.fst

# ==== Matlab ====
OCTAVE	?= octave
SCRIPT	?= matlab/sliding_window.m

.PHONY: all plot sim run wave lint clean realclean help

all: run

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

plot:
	@mkdir -p build
	$(OCTAVE) --no-gui --quiet --eval "\
	  run('$(SCRIPT)');"
	@echo "wran matlab script"

# Compile
sim: $(SIMV)

$(SIMV): $(BUILD_DIR) $(SRC) $(TB)
	$(IVERILOG) $(IVERILOG_FLAGS) -s $(TOP) -o $@ $(SRC) $(TB)

# Run simulation
run: sim
	$(VVP) $(SIMV) $(VVP_ARGS)

# Open GTKWave on the generated VCD
wave: run
	@test -f $(VCD) || { echo "No $(VCD) generated. Did your TB call $$dumpfile/$$dumpvars?"; exit 1; }
	$(GTKWAVE) $(VCD)

# Lint synthesizable RTL with Verilator
lint:
	@command -v verilator >/dev/null 2>&1 || { echo "verilator not found"; exit 1; }
	verilator --lint-only -Wall $(SRC)

clean:
	@rm -f  $(BUILD_DIR)/simv $(BUILD_DIR)/*.o $(BUILD_DIR)/*.vcd $(BUILD_DIR)/*.fst matlab/tb_large_output_matlab.txt matlab/input_data.mem matlab/plot.svg *output.txt

realclean: clean
	@rm -rf $(BUILD_DIR)

help:
	@echo "Targets:"
	@echo "  run      - build and run the simulation"
	@echo "  wave     - build, run, and open GTKWave on $(VCD)"
	@echo "  lint     - verilator lint on sources in src/"
	@echo "  clean    - remove build artifacts (keeps build/)"
	@echo "  realclean- remove build directory"
	@echo
	@echo "Variables (override on cmdline, e.g., 'make TB=tb/other.v TOP=other_tb'):"
	@echo "  TB        - testbench file (default: $(TB))"
	@echo "  TOP       - top testbench module name (default: $(TOP))"
	@echo "  VVP_ARGS  - extra args to vvp (e.g., +NOVCD)"
