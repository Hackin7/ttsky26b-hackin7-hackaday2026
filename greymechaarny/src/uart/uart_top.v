`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference Book: FPGA Prototyping By Verilog Examples Xilinx Spartan-3 Version
// Authored by: Dr. Pong P. Chu
// Published by: Wiley
//
// Adapted for the Basys 3 Artix-7 FPGA by David J. Marion
//
// Top Module for the Complete UART System
//
// Setup for 9600 Baud Rate
//
// For 9600 baud with 100MHz FPGA clock: 
// 9600 * 16 = 153,600
// 100 * 10^6 / 153,600 = ~651      (counter limit M)
// log2(651) = 10                   (counter bits N) 
//
// For 19,200 baud rate with a 100MHz FPGA clock signal:
// 19,200 * 16 = 307,200
// 100 * 10^6 / 307,200 = ~326      (counter limit M)
// log2(326) = 9                    (counter bits N)
//
// For 115,200 baud with 100MHz FPGA clock:
// 115,200 * 16 = 1,843,200
// 100 * 10^6 / 1,843,200 = ~52     (counter limit M)
// log2(52) = 6                     (counter bits N) 
//
// For 1500 baud with 100MHz FPGA clock:
// 1500 * 16 = 24,000
// 100 * 10^6 / 24,000 = ~4,167     (counter limit M)
// log2(4167) = 13                  (counter bits N) 

// For 460800 baud with 100MHz FPGA clock:
// 460800 * 16 = 7372800
// 100 * 10^6 / 7372800 = ~13.5633680556     (counter limit M)
// log2(14) = 4                    (counter bits N) 
//

// Comments:
// - Many of the variable names have been changed for clarity
//////////////////////////////////////////////////////////////////////////////////

module uart_top
    #(
        parameter   
            // UART Params
            DBITS = 8,          // number of data bits in a word
            SB_TICK = 16,       // number of stop bit / oversampling ticks
            
            // Baud Rate
            // BR_LIMIT = 14,     // baud rate generator counter limit
            // BR_BITS = 4,       // number of baud rate generator counter bits

            BR_LIMIT = 14,                // baud rate generator counter limit
            BR_BITS  = $clog2(BR_LIMIT),  // number of baud rate generator counter bits
            
            // Size
            FIFO_IN_SIZE = 4,        
            FIFO_OUT_SIZE = 4, 
            FIFO_OUT_SIZE_EXP = 32
    )
    (
        // General
        input clk_100MHz,               // FPGA clock
        input reset,                    // reset
        
        input [DBITS-1:0] write_data,   // data from Tx FIFO
        
        // Serial ports
        input rx,               // USB-RS232 Rx
        output tx,              // USB-RS232 Tx
        
        // Receiving
        output rx_char_received, 
        output rx_full,                 // do not write data to FIFO
        output rx_empty,                // no data to read from FIFO
        output [DBITS*FIFO_IN_SIZE - 1:0] rx_out,
        
        // Debugging
        output [DBITS*FIFO_OUT_SIZE - 1:0] tx_fifo_out,
        
        // Sending
        input tx_trigger,
        input [DBITS*FIFO_OUT_SIZE -1 :0] tx_in //2**FIFO_EXP_IN) -  1
    );
    
    // Connection Signals
    wire tick;                          // sample tick from baud rate generator
    // Instantiate Modules for UART Core
    baud_rate_generator 
        #(
            .M(BR_LIMIT), 
            .N(BR_BITS)
         ) 
        BAUD_RATE_GEN   
        (
            .clk_100MHz(clk_100MHz), 
            .reset(reset),
            .tick(tick)
         );
    
    // UART Receiver ///////////////////////////////////////////////////
    wire rx_done_tick;                  // data word received
    wire [DBITS-1:0] rx_data_out;       // from UART receiver to Rx FIFO
    uart_receiver
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_RX_UNIT
         (
            .clk_100MHz(clk_100MHz),
            .reset(reset),
            .rx(rx),
            .sample_tick(tick),
            
            .data_ready(rx_done_tick),
            .data_out(rx_data_out)
         );
    // above working
    

    assign rx_char_received = rx_done_tick;
    reg  [(DBITS * FIFO_IN_SIZE)-1:0] memory;
    wire [(DBITS * FIFO_IN_SIZE)-1:0] shifted_memory = memory << DBITS; 
    always @ (posedge clk_100MHz) begin
        if (rx_done_tick) begin
            memory <= shifted_memory | rx_data_out;
        end
    end
    assign rx_out = memory;
    
    // fifo_shift
    //      #(
    //          .DATA_SIZE(DBITS),
    //          .ADDR_SPACE(FIFO_IN_SIZE)
    //       )
    //       FIFO_RX_UNIT
    //       (
    //          .clk(clk_100MHz),
    //          .reset(reset),
    //          .write_to_fifo(rx_done_tick),
    //          //.shift(rx_done_tick), 
    //          .write_data_in(rx_data_out),
    //          .write_batch_to_fifo(0),
    //          .write_batch_data_in(0),
    //          .read_all_data_out(rx_out),
    //          .tick(read_tick)  
    //        );
    
    // UART Transmitter ////////////////////////////////////////////////
    
    wire tx_empty;                      // Tx FIFO has no data to transmit
    wire tx_fifo_not_empty;             // Tx FIFO contains data to transmit
    //wire [DBITS-1:0] tx_fifo_out;       // from Tx FIFO to UART transmitter
    
    fifo_shift
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE(FIFO_OUT_SIZE)
         )
         FIFO_TX_UNIT
         (
             .clk(clk_100MHz),
             .write_to_fifo(0),
             .write_data_in(0),
             .write_batch_to_fifo(tx_trigger),
             .write_batch_data_in(tx_in),
             .shift(tx_done_tick),
             .read_data_out_last(tx_fifo_out),
             .tick(read_tick)  
           );
    
    reg [FIFO_OUT_SIZE_EXP-1:0] count = 0;
    wire tx_done_tick;                  // data transmission complete
    reg tx_done_tick_latch = 0;
    wire tx_send = count != 0 & ~tx_trigger;
    uart_transmitter
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_TX_UNIT
         (
            .clk_100MHz(clk_100MHz),
            .reset(reset),
            .tx(tx),
            .sample_tick(tick),
            .tx_start(tx_send),
            .data_in(tx_fifo_out),
            .tx_done(tx_done_tick)
         );
    
    always @(posedge clk_100MHz) begin
        if (tx_trigger) begin
            count <= FIFO_OUT_SIZE; // Edge
        // Debug this part
        end else if (tx_done_tick != tx_done_tick_latch && tx_done_tick && count != 0) begin
            count <= count - 1;
        end
        tx_done_tick_latch <= tx_done_tick;
    end
endmodule
