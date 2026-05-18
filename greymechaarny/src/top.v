/*
Top module structure

Interconnect Pins
- Pins[0, 1] -> UART TX RX
- Pins[2] -> Valid Data Input (Pulse in the data) (in to FPGA)
- Pins[3] -> Valid Received Data (out from FPGA)
*/


module top(input clk_ext, input [4:0] btn, output [7:0] led, inout [7:0] interconnect);

    /// Internal Configuration ///////////////////////////////////////////
    wire clk_int;        // Internal OSCILLATOR clock
    defparam OSCI1.DIV = "3"; // Info: Max frequency for clock '$glbnet$clk': 162.00 MHz (PASS at 103.34 MHz)
    OSCG OSCI1 (.OSC(clk_int));

    wire clk = clk_int;
    localparam CLK_FREQ = 103_340_000; // EXT CLK

    reg [31:0] clk_stepdown_counter = 0;
    reg [31:0] clk_stepdown_count_val = 10;
    reg clk_slow = 0;
    always @ (posedge clk) begin
        clk_stepdown_counter <= clk_stepdown_counter + 1;
        if (clk_stepdown_counter >= clk_stepdown_count_val) begin
            clk_slow <= ~clk_slow;
            clk_stepdown_counter <= 0;
        end
    end

    
    /// UART ////////////////////////////////////////////////
    parameter DBITS = 8;
    parameter UART_FRAME_SIZE = 16;

    wire reset = interconnect[7] | ~btn[2];
    wire rx;
    wire tx    = interconnect[1];
    wire [UART_FRAME_SIZE*DBITS-1:0] uart_rx_out;
    wire [UART_FRAME_SIZE*DBITS-1:0] uart_tx_out; // = "asdfghjkl";
    wire                             uart_tx_controller_send; // = 0;
    wire                             uart_rx_received;
    wire rx_full, rx_empty;
    // Complete UART Core
    uart_top 
        #(
            .FIFO_IN_SIZE(UART_FRAME_SIZE),
            .FIFO_OUT_SIZE(UART_FRAME_SIZE),
            .FIFO_OUT_SIZE_EXP(32)
        ) 
        UART_UNIT
        (
            .clk_100MHz  (clk),
            .reset       (reset),
            
            .rx          (interconnect[0]),
            .tx          (tx),
            
            .rx_char_received (uart_rx_received),
            .rx_full     (rx_full),
            .rx_empty    (rx_empty),
            .rx_out      (uart_rx_out),
            
            .tx_trigger  (uart_tx_controller_send), // | ~btn[1]),
            .tx_in       (uart_tx_out) 
        );

    reg [7:0] rx_char_count = 0;
    reg din_valid = 0;
    reg din_valid_dly = 0;
    reg [UART_FRAME_SIZE*DBITS-1:0] din_dly;
    always @ (posedge clk) begin
        if (reset) begin
            rx_char_count <= 0; 
            din_valid     <= 0;
            din_dly       <= 0;
        end else if (uart_rx_received) begin
            if (rx_char_count >= 15) begin
                rx_char_count <= 0;
                din_valid     <= 1; // Trigger, then pulse din_valid
            end else begin
                rx_char_count <= rx_char_count + 1;
                din_valid     <= 0;
            end
        end else if (rx_char_count == 0) begin
            din_valid     <= 0;
            din_dly       <= uart_rx_out;
        end
    end

    // Coprocessor (TT wrapper via UART adapter) ///////////////////////
    uart_tt_adapter u_coprocessor (
        .clk        (clk),
        .rst        (reset),

        .din         (din_dly),
        .din_valid   (din_valid),
        .dout        (uart_tx_out),
        .dout_valid  (uart_tx_controller_send), 

        .control     (interconnect[6:2])
    );

    /// Control Logic ///////////////////////////////////////////////
    
    assign led = (
        ~btn[4] ? uart_rx_out[8*(1)-1:8*(0)]: // UART Parsing Data
        ~btn[3] ? interconnect: // UART Parsing Data
        ~btn[1] ? rx_char_count : 
        ~btn[0] ? 8'b01010101 : //viz_count:
        8'b10101010 // viz_position
    );

endmodule
