# Sample Circuitpython Code
import board
import busio
import digitalio
import time
#import hardware.main
import hardware.fpga

PATH="/apps/aoc25/prob1/"
#hardware.main.hw_state["fpga_overlay"].deinit()


def neg_int(x, bits):
    # If MSB is set, convert to negative
    if x & (1 << (bits - 1)):
        x_signed = x - (1 << bits)
    else:
        x_signed = x
    return x_signed

### Configure UART GPIO #########################
class FpgaCoprocessor():    
    def clear_pins(self):
        ### Need clear Pins first #######################
        DATA_PINS_NO = [board.GP8, board.GP9, board.GP10, board.GP11, board.GP12]
        pins = []
        for p in DATA_PINS_NO:
            d = digitalio.DigitalInOut(p)
            d.direction = digitalio.Direction.OUTPUT
            d.value = False
            pins.append(d)
                    
        for d in pins:
            d.deinit()
    
    def __init__(self):
        self.clear_pins()
        self.FRAME_SIZE = 16
        self.uart = busio.UART(board.GP8, board.GP9, baudrate=460800, timeout=0.1)
        DATA_PINS_NO = [board.GP10, board.GP11, board.GP12, board.GP13, board.GP14, board.GP15]
        pins = []
        for p in DATA_PINS_NO:
            d = digitalio.DigitalInOut(p)
            d.direction = digitalio.Direction.OUTPUT
            d.value = False
            pins.append(d)
        self.pins = pins
    
    def reset(self):
        self.pins[5].value = 1
        time.sleep(0.1)
        self.pins[5].value = 0
        time.sleep(0.1)
        
    def set_mode(self, a, b, c):
        self.pins[0].value = a 
        self.pins[1].value = b
        self.pins[2].value = c
    
    def part_b_enable(self, x):
        self.pins[3].value = x
    def write_int(self, val):
        n = val
        if val < 0:
            n = 1 << (self.FRAME_SIZE*8) 
            n = n + val  # - val 
            #print("Val:", val, n) # Conversion debugging
        try:
            s = n.to_bytes(self.FRAME_SIZE, byteorder="big")
        except Exception as e:
            print(n, e)
            raise e
        #print(s)
        self.uart.write(s)
    
    def read_int(self):
        #s = fp.uart.read()[-self.FRAME_SIZE :]
        s = fp.uart.read()[-4 :]
        n = int.from_bytes(s, byteorder="big")
        #print(len(s), s, n, "", end="")
        # Convert to signed
        n = neg_int(n, 4*8)
        return n

##################################################################################
fp = None

def setup(bitstream_upload=True, hardcaml=False):
    if bitstream_upload:
        bitstream_path = PATH+"/coprocessor_verilog.bit"
        if hardcaml: bitstream_path = PATH+"/coprocessor_hardcaml.bit"
        h = hardware.fpga.upload_bitstream(bitstream_path)
        h.deinit()
    
    global fp
    fp = FpgaCoprocessor()
    fp.set_mode(0, 0, 0) # Normal Computation
    # Reset

    fp.set_mode(1, 0, 0) # dly
    fp.set_mode(0, 1, 0) # position data
    fp.set_mode(0, 0, 1) # Get Final Answer
    
    
def run(file="input.txt", interleave=False, debug=False):
    fp.reset()
    for i in range(3): # Fill up pipeline stages
        fp.write_int(0)
        if debug: print("stage:", 0, fp.read_int())
    
    # Read Text file
    count = 0
    position = 50
    with open(PATH+file) as f:
        for line in f:
            str_direction = line[0]
            str_number = line[1:].strip()
            sign = 1 if str_direction == "R" else -1
            value = int(str_number) * sign
            
            # ### Solution Without FPGA LMAO #####################
            # position = (position + value) % 100
            # if position == 0: count += 1
            position = (position + value) % 100
            
            fp.write_int(value)
            if interleave:
                fp.read_int() # print("stage:", value, fp.read_int(), position)
                fp.write_int(0)
            if debug: print("stage:", value, fp.read_int(), position)
        
    fp.write_int(0) # Clear pipeline stages
    fp.read_int()
    fp.write_int(0) # Clear pipeline stages
    ans = fp.read_int()
    print("Ans:", ans)
    return ans

def run_interactive():
    setup((input("type something to update fpga: ") != ""), hardcaml=False)
    # Just to clear out
    run("input_sample.txt", debug=False)
    run()
    fp.part_b_enable(1)
    run()
    
if __name__ == "__main__":
    run_interactive()
