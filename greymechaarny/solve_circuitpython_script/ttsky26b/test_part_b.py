# Part B smoke test for hackin7_coprocessor.bit (does not modify D:/apps solve.py).
#
# Usage (fresh mpremote session):
#   mpremote connect COM17 run hackin7/ttsky26b/test_part_b.py
#
# Expect: warmup Ans: 0 (or pipeline), then after reset Ans: 6 on input_sample.txt

import sys

sys.path.insert(0, "/hackin7/ttsky26b")

import hardware.fpga
import solve

BIT = "/hackin7/ttsky26b/hackin7_coprocessor.bit"
EXPECTED = 6

h = hardware.fpga.upload_bitstream(BIT)
h.deinit()

solve.fp = solve.FpgaCoprocessor()
solve.fp.set_mode(0, 0, 0)
solve.fp.set_mode(1, 0, 0)
solve.fp.set_mode(0, 1, 0)
solve.fp.set_mode(0, 0, 1)
solve.fp.part_b_enable(1)

solve.run("input_sample.txt")
solve.fp.reset()
ans = solve.run("input_sample.txt")

print("Part B after reset:", ans)
if ans != EXPECTED:
    raise SystemExit(f"FAIL: expected {EXPECTED}, got {ans}")
print("PASS part B sample")
