`timescale 1ns/1ps
// Replicate cocotb test.py stimulus on tt_um (must get loops_a == 3).
// Result is read via the 4-cycle uo_out port read protocol (no hierarchy probes).

module tb_cocotb_match;
    localparam CTRL_PART_A = 5'b00100;

    reg clk;
    reg rst_n;
    reg [7:0] ui_in, uio_in;
    wire [7:0] uo_out;

    tt_um_hackin7_coprocessor dut (
        .clk(clk), .rst_n(rst_n), .ena(1'b1),
        .ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
        .uio_out(), .uio_oe()
    );

    reg [31:0] port_result;

    always #5 clk = ~clk;

    function [127:0] pack_le32;
        input signed [31:0] val;
        pack_le32 = {96'b0, val};
    endfunction

    task load_bytes(input [127:0] data);
        integer i;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                uio_in = data[i * 8 +: 8];
                ui_in  = 8'b1;
                @(posedge clk);
                ui_in  = 8'd0;
                @(posedge clk);
            end
        end
    endtask

    task run_step(input signed [31:0] val);
        begin
            load_bytes(pack_le32(val));
            ui_in = {1'b0, CTRL_PART_A, 2'b10};
            @(posedge clk);
            ui_in = 8'd0;
            @(posedge clk);
            repeat (64) @(posedge clk);
        end
    endtask

    // Read 32-bit result via 4-cycle port read (ui_in[7]=1, ui_in[6:5]=byte_sel)
    task read_result32;
        integer sel;
        begin
            port_result = 0;
            for (sel = 0; sel < 4; sel = sel + 1) begin
                ui_in  = {1'b1, sel[1:0], 5'd0};
                uio_in = 8'd0;
                @(posedge clk);
                port_result[sel * 8 +: 8] = uo_out;
                ui_in = 8'd0;
                @(posedge clk);
            end
        end
    endtask

    initial begin
        integer i;
        clk = 0; rst_n = 0; ui_in = 0; uio_in = 0;

        repeat (10) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        for (i = 0; i < 3; i = i + 1)
            run_step(0);

        run_step(-68);
        run_step(-30);
        run_step(48);
        run_step(-5);
        run_step(60);
        run_step(-55);
        run_step(-1);
        run_step(-99);
        run_step(14);
        run_step(-82);
        run_step(0);
        run_step(0);
        repeat (64) @(posedge clk);

        read_result32();
        if (port_result === 32'd3)
            $display("PASS cocotb_match port_result=3");
        else
            $display("FAIL cocotb_match port_result=%0d expected 3", port_result);

        $finish;
    end
endmodule
