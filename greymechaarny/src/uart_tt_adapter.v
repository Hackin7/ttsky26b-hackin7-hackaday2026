// UART frame (128-bit din_valid pulse) to Tiny Tapeout tt_um_hackin7_coprocessor pin protocol.
// Drop-in replacement for coprocessor in greymechaarny/src/top.v.

`default_nettype none

module uart_tt_adapter (
    input  wire         clk,
    input  wire         rst,
    input  wire [127:0] din,
    input  wire         din_valid,
    input  wire [4:0]   control,
    output reg  [127:0] dout,
    output reg          dout_valid
);

    localparam SETTLE_CYCLES = 64;

    localparam S_IDLE        = 3'd0;
    localparam S_STROBE_ON    = 3'd1;
    localparam S_STROBE_OFF   = 3'd2;
    localparam S_COMPUTE_ON   = 3'd3;
    localparam S_COMPUTE_OFF  = 3'd4;
    localparam S_SETTLE       = 3'd5;
    localparam S_TX_PULSE     = 3'd6;

    reg [2:0]       state;
    reg [3:0]       byte_i;
    reg [7:0]       settle_cnt;
    reg [127:0]     latched_din;
    reg [4:0]       latched_ctrl;
    reg [127:0]     latched_dout;

    reg [7:0]       ui_in;
    reg [7:0]       uio_in;
    wire [7:0]      uo_out;

    (* keep_hierarchy = "yes" *)
    tt_um_hackin7_coprocessor u_tt (
        .clk    (clk),
        .rst_n  (~rst),
        .ena    (1'b1),
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(),
        .uio_oe ()
    );

    wire [127:0] cp_dout       = u_tt.u_coprocessor.dout;
    wire         cp_dout_valid = u_tt.u_coprocessor.dout_valid;

    wire _unused_uo = |uo_out;

    always @(posedge clk) begin
        dout_valid <= 1'b0;

        if (rst) begin
            state        <= S_IDLE;
            byte_i       <= 4'd0;
            settle_cnt   <= 8'd0;
            latched_din  <= 128'd0;
            latched_ctrl <= 5'd0;
            latched_dout <= 128'd0;
            dout         <= 128'd0;
            ui_in        <= 8'd0;
            uio_in       <= 8'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    ui_in  <= 8'd0;
                    uio_in <= 8'd0;
                    if (din_valid) begin
                        latched_din  <= din;
                        latched_ctrl <= control;
                        byte_i       <= 4'd0;
                        state        <= S_STROBE_ON;
                    end
                end

                S_STROBE_ON: begin
                    uio_in <= latched_din[byte_i * 8 +: 8];
                    ui_in  <= 8'b0000_0001;
                    state  <= S_STROBE_OFF;
                end

                S_STROBE_OFF: begin
                    ui_in  <= 8'd0;
                    uio_in <= latched_din[byte_i * 8 +: 8];
                    if (byte_i >= 4'd15)
                        state <= S_COMPUTE_ON;
                    else begin
                        byte_i <= byte_i + 4'd1;
                        state  <= S_STROBE_ON;
                    end
                end

                S_COMPUTE_ON: begin
                    ui_in  <= {1'b0, latched_ctrl, 2'b10};
                    uio_in <= 8'd0;
                    state  <= S_COMPUTE_OFF;
                end

                S_COMPUTE_OFF: begin
                    ui_in      <= 8'd0;
                    uio_in     <= 8'd0;
                    settle_cnt <= SETTLE_CYCLES[7:0] - 8'd1;
                    state      <= S_SETTLE;
                end

                S_SETTLE: begin
                    ui_in  <= 8'd0;
                    uio_in <= 8'd0;
                    if (settle_cnt == 8'd0) begin
                        latched_dout <= cp_dout;
                        state        <= S_TX_PULSE;
                    end else begin
                        settle_cnt <= settle_cnt - 8'd1;
                    end
                end

                S_TX_PULSE: begin
                    ui_in      <= 8'd0;
                    uio_in     <= 8'd0;
                    dout       <= latched_dout;
                    dout_valid <= 1'b1;
                    state      <= S_IDLE;
                end

                default: begin
                    ui_in  <= 8'd0;
                    uio_in <= 8'd0;
                    state  <= S_IDLE;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
