`timescale 1ns /1ps
//////////////////////////////////////////////////////////////////////////////////////////
// Reference book:
// "FPGA Prototyping by Verilog Examples"
// "Xilinx Spartan-3 Version"
// Dr. Pong P. Chu
// Wiley
//
// Adapted for Artix-7
// David J. Marion
//
// Parameterized FIFO Unit for the UART System
// 
// Comments:
// - Many of the variable names have been changed for clarity
//////////////////////////////////////////////////////////////////////////////////////////

// Modified to basically become a shift register
 module fifo_shift
	#(
	   parameter	DATA_SIZE  = 8,	       // number of bits in a data word
				    ADDR_SPACE = 4	           // number of addresses
	)
	(
	   input clk,                              // FPGA clock           
	   input reset,                            // reset button
	   
       input write_to_fifo,                    // signal start writing to FIFO
	   input [DATA_SIZE-1:0] write_data_in,    // data word into FIFO
       
       input write_batch_to_fifo,              // signal start writing to FIFO
       input [(DATA_SIZE * ADDR_SPACE)-1:0] write_batch_data_in,       // data word into FIFO
       
       input shift,
       
	   output [DATA_SIZE-1:0] read_data_out,   // first word into FIFO
       output [DATA_SIZE-1:0] read_data_out_last,   // last word out of FIFO
	   output [(DATA_SIZE * ADDR_SPACE)-1:0] read_all_data_out,
	   output reg tick
);

	// signal declaration
	reg [(DATA_SIZE * ADDR_SPACE)-1:0] memory;		// memory array register
	reg fifo_full, fifo_empty, full_buff, empty_buff;
    
    wire [(DATA_SIZE * ADDR_SPACE)-1:0]shifted_memory = memory << DATA_SIZE; // auto truncated
    
    reg past_shift = 0;
	// register file (memory) write operation
	always @(posedge clk) begin
	    tick <= 1'b0;
        if(write_batch_to_fifo) begin
            memory <= write_batch_data_in;
			tick = 1'b1;
		end
		if(write_to_fifo || (shift != past_shift && shift == 1)) begin // Shift operation
		    memory <= shifted_memory | write_data_in ;  // Make space for new byte
			tick <= 1'b1;
		end 
        past_shift <= shift;
    end
    
	// register file (memory) read operation
	assign read_data_out = memory[DATA_SIZE-1:0];
	assign read_data_out_last = memory[(DATA_SIZE * ADDR_SPACE)-1:(DATA_SIZE * (ADDR_SPACE-1))];
	assign read_all_data_out = memory;
endmodule
