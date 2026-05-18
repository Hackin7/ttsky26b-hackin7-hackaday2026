`timescale 1ns/1ps
// Replicate cocotb test.py stimulus on tt_um (must get loops_a == 3)

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

    wire [31:0] loops_a = dut.u_coprocessor.calc_num_loops_a;

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

        if (loops_a === 32'd3)
            $display("PASS cocotb_match loops_a=3");
        else
            $display("FAIL cocotb_match loops_a=%0d expected 3", loops_a);

        $finish;
    end
endmodule
