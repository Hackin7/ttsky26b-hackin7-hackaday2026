/*
 * Tiny Tapeout wrapper for the Hardcaml AoC coprocessor (coprocessor.v unchanged).
 *
 * Load 16 bytes, pulse compute, read 32-bit result from the low word of dout.
 *
 * ui_in[0]  byte_strobe  - latch uio_in into din[byte_idx*8 +: 8], advance index
 * ui_in[1]  compute      - pulse din_valid for one cycle (after 16 bytes loaded)
 * ui_in[6:2] control[4:0]
 * uio_in[7:0] data byte
 *
 * uo_out[7:0]  result[7:0] when dout_valid has been seen; uo_out[0] is dout_valid sticky
 */

`default_nettype none

module tt_um_hackin7_coprocessor (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire rst = ~rst_n;

    wire        byte_strobe = ui_in[0];
    wire        compute     = ui_in[1];
    wire [4:0]  control     = ui_in[6:2];

    reg  [3:0]   byte_idx;
    reg  [127:0] din_reg;
    reg          din_valid;
    wire [127:0] dout;
    wire         dout_valid_cp;

    reg          result_valid;
    reg  [31:0]  result_reg;

    always @(posedge clk) begin
        if (rst) begin
            byte_idx     <= 4'd0;
            din_reg      <= 128'd0;
            din_valid    <= 1'b0;
            result_valid <= 1'b0;
            result_reg   <= 32'd0;
        end else begin
            din_valid <= 1'b0;

            if (byte_strobe) begin
                din_reg[byte_idx * 8 +: 8] <= uio_in;
                byte_idx <= byte_idx + 4'd1;
            end

            if (compute) begin
                din_valid <= 1'b1;
                byte_idx  <= 4'd0;
            end

            if (dout_valid_cp) begin
                result_valid <= 1'b1;
                result_reg   <= dout[31:0];
            end
        end
    end

    coprocessor u_coprocessor (
        .clk        (clk),
        .rst        (rst),
        .din        (din_reg),
        .din_valid  (din_valid),
        .control    (control),
        .dout       (dout),
        .dout_valid (dout_valid_cp)
    );

    assign uo_out   = {result_reg[6:0], result_valid};
    assign uio_out  = 8'd0;
    assign uio_oe   = 8'd0;

    wire _unused = &{ena, dout[127:32], dout_valid_cp, 1'b0};

endmodule
