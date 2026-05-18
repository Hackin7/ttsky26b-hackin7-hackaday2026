PROJ = hackin7_coprocessor

SRC_TOP     = src/top.v
SRC_ADAPTER = src/uart_tt_adapter.v
SRC_UART    = src/uart/uart_top.v src/uart/uart_receiver.v \
              src/uart/uart_transmitter.v src/uart/baud_rate_generator.v \
              src/uart/fifo_shift.v
SRC_TT      = ../src/project.v ../src/coprocessor.v

VERILOG_SRCS = $(SRC_TOP) $(SRC_ADAPTER) $(SRC_UART) $(SRC_TT)
SIM_SRCS     = $(SRC_ADAPTER) $(SRC_TT) test/tb_adapter.v
all: $(PROJ).bit

%.json: $(VERILOG_SRCS)
	yosys -p "read_verilog $(VERILOG_SRCS); synth_ecp5 -top top -json $@"

%_out.config: %.json pinout.lpf
	nextpnr-ecp5 --json $< --textcfg $@ --25k --package CABGA256 \
	  --lpf pinout.lpf --timing-allow-fail

%.bit: %_out.config
	ecppack --svf $@.svf $< $@

sim: test/tb_adapter.vvp test/tb_cocotb_match.vvp
	vvp test/tb_adapter.vvp
	vvp test/tb_cocotb_match.vvp

test/tb_adapter.vvp: $(SIM_SRCS)
	iverilog -g2012 -o $@ $(SIM_SRCS)
	@echo "Built $@"

test/tb_cocotb_match.vvp: $(SRC_TT) test/tb_cocotb_match.v
	iverilog -g2012 -o $@ $(SRC_TT) test/tb_cocotb_match.v
	@echo "Built $@"

clean:
	rm -f *.svf *.bit *.config *.json test/*.vvp test/*.vcd

.PHONY: all sim clean
