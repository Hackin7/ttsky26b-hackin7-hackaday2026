`timescale 1ns/1ps

// Compare uart_tt_adapter (UART din_valid frame) against tt_um driven with cocotb pin protocol.
// Result comparison uses the TT 4-cycle port read (ui_in[7]=1, ui_in[6:5]=byte_sel)
// rather than hierarchy probes so it mirrors what silicon actually exposes.

module tb_adapter;
    localparam CTRL_PART_A = 5'b00100;
    localparam CTRL_PART_B = 5'b01100;

    reg clk;
    reg rst;

    reg  [127:0] din;
    reg          din_valid;
    reg  [4:0]   control;

    wire [127:0] adp_dout;
    wire         adp_dout_valid;

    reg  [7:0] ref_ui_in;
    reg  [7:0] ref_uio_in;
    wire [7:0] ref_uo_out;

    reg [31:0] ref_result32;

    integer errors;
    integer expected_loops;

    uart_tt_adapter u_adapter (
        .clk        (clk),
        .rst        (rst),
        .din        (din),
        .din_valid  (din_valid),
        .control    (control),
        .dout       (adp_dout),
        .dout_valid (adp_dout_valid)
    );

    tt_um_hackin7_coprocessor u_ref (
        .clk    (clk),
        .rst_n  (~rst),
        .ena    (1'b1),
        .ui_in  (ref_ui_in),
        .uo_out (ref_uo_out),
        .uio_in (ref_uio_in),
        .uio_out(),
        .uio_oe ()
    );

    always #5 clk = ~clk;

    function [127:0] pack_be32;
        input signed [31:0] val;
        integer i;
        reg [7:0] b [0:15];
        begin
            b[15] = val[7:0];
            b[14] = val[15:8];
            b[13] = val[23:16];
            b[12] = val[31:24];
            for (i = 0; i < 12; i = i + 1)
                b[i] = val[31] ? 8'hff : 8'h00;
            pack_be32 = {b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
                         b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]};
        end
    endfunction

    function [127:0] pack_le32;
        input signed [31:0] val;
        pack_le32 = {96'b0, val};
    endfunction

    task automatic tt_load_frame(input [127:0] data);
        integer i;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                ref_uio_in = data[i * 8 +: 8];
                ref_ui_in  = 8'b0000_0001;
                @(posedge clk);
                ref_ui_in  = 8'd0;
                @(posedge clk);
            end
        end
    endtask

    task automatic tt_compute(input [4:0] ctrl);
        begin
            ref_ui_in  = {1'b0, ctrl, 2'b10};
            ref_uio_in = 8'd0;
            @(posedge clk);
            ref_ui_in  = 8'd0;
            @(posedge clk);
            repeat (64) @(posedge clk);
        end
    endtask

    task automatic ref_step(input [127:0] frame, input [4:0] ctrl);
        begin
            tt_load_frame(frame);
            tt_compute(ctrl);
        end
    endtask

    // Read 32-bit result from ref tt_um via 4-cycle port read protocol
    task automatic ref_read_result32;
        integer sel;
        begin
            ref_result32 = 0;
            for (sel = 0; sel < 4; sel = sel + 1) begin
                ref_ui_in  = {1'b1, sel[1:0], 5'd0};
                ref_uio_in = 8'd0;
                @(posedge clk);
                ref_result32[sel * 8 +: 8] = ref_uo_out;
                ref_ui_in  = 8'd0;
                @(posedge clk);
            end
        end
    endtask

    task automatic adapter_step(input [127:0] frame, input [4:0] ctrl);
        integer timeout;
        begin
            din       = frame;
            control   = ctrl;
            din_valid = 1'b0;
            @(posedge clk);
            din_valid = 1'b1;
            @(posedge clk);
            din_valid = 1'b0;

            timeout = 0;
            while (!adp_dout_valid && timeout < 1000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (!adp_dout_valid) begin
                $display("FAIL: adapter dout_valid timeout");
                errors = errors + 1;
            end
            @(posedge clk);
        end
    endtask

    task automatic run_pair(input [127:0] frame, input [4:0] ctrl, input string msg);
        // solve.py s[-4:] reads adp_dout[31:0] (UART sends [31:0] as last 4 wire bytes)
        begin
            ref_step(frame, ctrl);
            adapter_step(frame, ctrl);
            ref_read_result32();
            if (ref_result32 !== adp_dout[31:0]) begin
                $display("FAIL %s: ref=%0d adapter=%0d",
                         msg, ref_result32, adp_dout[31:0]);
                errors = errors + 1;
            end else
                $display("PASS %s: result=%0d", msg, ref_result32);
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        din = 0;
        din_valid = 0;
        control = 0;
        ref_ui_in = 0;
        ref_uio_in = 0;
        errors = 0;

        repeat (4) @(posedge clk);
        rst = 0;
        repeat (4) @(posedge clk);

        run_pair(pack_le32(32'd0), CTRL_PART_A, "prime 0 #1");
        run_pair(pack_le32(32'd0), CTRL_PART_A, "prime 0 #2");
        run_pair(pack_le32(32'd0), CTRL_PART_A, "prime 0 #3");
        run_pair(pack_le32(-68), CTRL_PART_A, "L68");
        run_pair(pack_le32(-30), CTRL_PART_A, "L30");
        run_pair(pack_le32(48), CTRL_PART_A, "R48");
        run_pair(pack_le32(-5), CTRL_PART_A, "L5");
        run_pair(pack_le32(60), CTRL_PART_A, "R60");
        run_pair(pack_le32(-55), CTRL_PART_A, "L55");
        run_pair(pack_le32(-1), CTRL_PART_A, "L1");
        run_pair(pack_le32(-99), CTRL_PART_A, "L99");
        run_pair(pack_le32(14), CTRL_PART_A, "R14");
        run_pair(pack_le32(-82), CTRL_PART_A, "L82");

        // Match cocotb test.py drain: two zero steps + settle before read
        run_pair(pack_le32(32'd0), CTRL_PART_A, "drain 0 #1");
        run_pair(pack_le32(32'd0), CTRL_PART_A, "drain 0 #2");
        repeat (64) @(posedge clk);

        expected_loops = 3;
        if (adp_dout[31:0] !== 32'd3) begin
            $display("FAIL AoC sample final: adp_dout[31:0]=%0d expected 3", adp_dout[31:0]);
            errors = errors + 1;
        end else
            $display("PASS AoC sample final loops_a=%0d", adp_dout[31:0]);

        // Host UART big-endian frame (write_int layout)
        rst = 1;
        repeat (4) @(posedge clk);
        rst = 0;
        repeat (4) @(posedge clk);
        run_pair(pack_be32(32'd10), CTRL_PART_A, "host BE write_int(10)");

        // --- Part B (control[3]=1, sample expects loops_b == 6) ---
        rst = 1;
        repeat (4) @(posedge clk);
        rst = 0;
        repeat (4) @(posedge clk);
        control = CTRL_PART_B;

        run_pair(pack_le32(32'd0), CTRL_PART_B, "B prime 0 #1");
        run_pair(pack_le32(32'd0), CTRL_PART_B, "B prime 0 #2");
        run_pair(pack_le32(32'd0), CTRL_PART_B, "B prime 0 #3");
        run_pair(pack_le32(-68), CTRL_PART_B, "B L68");
        run_pair(pack_le32(-30), CTRL_PART_B, "B L30");
        run_pair(pack_le32(48), CTRL_PART_B, "B R48");
        run_pair(pack_le32(-5), CTRL_PART_B, "B L5");
        run_pair(pack_le32(60), CTRL_PART_B, "B R60");
        run_pair(pack_le32(-55), CTRL_PART_B, "B L55");
        run_pair(pack_le32(-1), CTRL_PART_B, "B L1");
        run_pair(pack_le32(-99), CTRL_PART_B, "B L99");
        run_pair(pack_le32(14), CTRL_PART_B, "B R14");
        run_pair(pack_le32(-82), CTRL_PART_B, "B L82");
        run_pair(pack_le32(32'd0), CTRL_PART_B, "B drain 0 #1");
        run_pair(pack_le32(32'd0), CTRL_PART_B, "B drain 0 #2");
        repeat (64) @(posedge clk);

        if (adp_dout[31:0] !== 32'd6) begin
            $display("FAIL Part B final: adp_dout[31:0]=%0d expected 6", adp_dout[31:0]);
            errors = errors + 1;
        end else
            $display("PASS Part B final loops_b=%0d", adp_dout[31:0]);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
