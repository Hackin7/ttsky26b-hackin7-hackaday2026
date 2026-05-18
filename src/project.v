/*
 * Tiny Tapeout wrapper for the Hardcaml AoC coprocessor (coprocessor.v unchanged).
 *
 * Load 16 bytes, pulse compute, then read the full 32-bit result via 4-cycle port read.
 *
 * --- Load / compute phase (ui_in[7] = 0) ---
 * ui_in[0]    byte_strobe  - latch uio_in into din[byte_idx*8 +: 8], advance index
 * ui_in[1]    compute      - pulse din_valid for one cycle (after 16 bytes loaded)
 * ui_in[6:2]  control[4:0]
 * uio_in[7:0] data byte
 * uo_out[7:0] = {7'b0, result_valid}  (status only)
 *
 * --- Result read phase (ui_in[7] = 1, ui_in[1:0] must be 0) ---
 * ui_in[6:5]  byte_sel[1:0]  - selects byte of result_reg (0=LSB .. 3=MSB, little-endian)
 * uo_out[7:0] = result_reg[byte_sel*8 +: 8] when result_valid, else 8'h00
 *
 * Read sequence: assert ui_in[7]=1 + byte_sel, wait one rising edge, sample uo_out,
 * clear ui_in. Repeat for byte_sel 0..3 to assemble full 32-bit result.
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

    wire        byte_strobe     = ui_in[0];
    wire        compute         = ui_in[1];
    wire [4:0]  control         = ui_in[6:2];
    wire        result_read     = ui_in[7];
    wire [1:0]  result_byte_sel = ui_in[6:5];

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

    assign uo_out   = result_read
                      ? (result_valid ? result_reg[result_byte_sel * 8 +: 8] : 8'hFF)
                      : {7'b0, result_valid};
    assign uio_out  = 8'd0;
    assign uio_oe   = 8'd0;

    wire _unused = &{ena, dout[127:32], dout_valid_cp, 1'b0};

endmodule
