/* Code Generated from hardcaml */

module coprocessor (
    clk,
    din,
    rst,
    din_valid,
    control,
    dout,
    dout_valid
);

    input clk;
    input [127:0] din;
    input rst;
    input din_valid;
    input [4:0] control;
    output [127:0] dout;
    output dout_valid;

    wire [31:0] _45;
    wire _71;
    wire _21;
    wire _32;
    wire _33;
    wire _34;
    wire _24;
    reg _36;
    wire _2;
    reg calc_prev_computing_ptive;
    wire _69;
    wire _72;
    wire [30:0] _68;
    wire [31:0] _73;
    wire [31:0] _74;
    wire [31:0] _75;
    wire [31:0] _61;
    wire [31:0] _62;
    wire [31:0] _63;
    wire _40;
    wire _41;
    reg _42;
    wire _3;
    reg calc_position_was_zero;
    wire _56;
    wire [31:0] _57;
    wire [31:0] _58;
    wire [31:0] _53;
    wire [31:0] _49;
    wire _50;
    wire _51;
    wire [31:0] _54;
    wire _48;
    wire [31:0] _59;
    wire [31:0] _60;
    wire [31:0] _64;
    wire [31:0] _76;
    reg [31:0] _77;
    wire [31:0] _4;
    reg [31:0] calc_num_loops_b;
    wire _102;
    wire [31:0] _103;
    wire [31:0] _104;
    wire [1:0] _19;
    wire [1:0] _94;
    wire _66;
    wire _67;
    wire [1:0] _95;
    wire [31:0] _43;
    wire [31:0] _89;
    wire _31;
    wire [31:0] _90;
    wire [31:0] _86;
    wire _30;
    wire [31:0] _87;
    wire _28;
    wire _29;
    wire [31:0] _91;
    wire [127:0] _80;
    wire _6;
    wire [127:0] _8;
    reg [127:0] _81;
    wire [31:0] _82;
    wire [31:0] _83;
    wire [31:0] _78;
    wire _10;
    wire [31:0] _79;
    wire [31:0] _84;
    reg [31:0] _92;
    wire [31:0] _11;
    reg [31:0] calc_position;
    wire _44;
    wire [1:0] _96;
    wire [1:0] _35;
    wire _13;
    wire [1:0] _93;
    reg [1:0] _97;
    wire [1:0] _14;
    (* fsm_encoding="one_hot" *)
    reg [1:0] _20;
    reg [31:0] _105;
    wire [31:0] _15;
    reg [31:0] calc_num_loops_a;
    wire [4:0] _17;
    wire _107;
    wire [31:0] _108;
    wire [95:0] _106;
    wire [127:0] _109;
    assign _45 = 32'b00000000000000000000000000000000;
    assign _71 = calc_position == _45;
    assign _21 = 1'b0;
    assign _32 = 1'b1;
    assign _33 = _31 ? _32 : calc_prev_computing_ptive;
    assign _34 = _29 ? _33 : calc_prev_computing_ptive;
    assign _24 = _13 ? _21 : calc_prev_computing_ptive;
    always @* begin
        case (_20)
        2'b00:
            _36 <= _24;
        2'b01:
            _36 <= _34;
        default:
            _36 <= calc_prev_computing_ptive;
        endcase
    end
    assign _2 = _36;
    always @(posedge _6) begin
        if (_10)
            calc_prev_computing_ptive <= _21;
        else
            calc_prev_computing_ptive <= _2;
    end
    assign _69 = ~ calc_prev_computing_ptive;
    assign _72 = _69 & _71;
    assign _68 = 31'b0000000000000000000000000000000;
    assign _73 = { _68,
                   _72 };
    assign _74 = calc_num_loops_b + _73;
    assign _75 = _67 ? _74 : _64;
    assign _61 = 32'b00000000000000000000000000000001;
    assign _62 = calc_num_loops_b + _61;
    assign _63 = _31 ? _62 : _60;
    assign _40 = calc_position == _45;
    assign _41 = _13 ? _40 : calc_position_was_zero;
    always @* begin
        case (_20)
        2'b00:
            _42 <= _41;
        default:
            _42 <= calc_position_was_zero;
        endcase
    end
    assign _3 = _42;
    always @(posedge _6) begin
        if (_10)
            calc_position_was_zero <= _21;
        else
            calc_position_was_zero <= _3;
    end
    assign _56 = ~ calc_position_was_zero;
    assign _57 = { _68,
                   _56 };
    assign _58 = calc_num_loops_b + _57;
    assign _53 = calc_num_loops_b + _61;
    assign _49 = 32'b11111111111111111111111110011100;
    assign _50 = _49 < calc_position;
    assign _51 = ~ _50;
    assign _54 = _51 ? _53 : calc_num_loops_b;
    assign _48 = _49 < calc_position;
    assign _59 = _48 ? _58 : _54;
    assign _60 = _30 ? _59 : calc_num_loops_b;
    assign _64 = _29 ? _63 : _60;
    assign _76 = _44 ? _75 : _64;
    always @* begin
        case (_20)
        2'b01:
            _77 <= _76;
        default:
            _77 <= calc_num_loops_b;
        endcase
    end
    assign _4 = _77;
    always @(posedge _6) begin
        if (_10)
            calc_num_loops_b <= _45;
        else
            calc_num_loops_b <= _4;
    end
    assign _102 = calc_position == _45;
    assign _103 = { _68,
                    _102 };
    assign _104 = calc_num_loops_a + _103;
    assign _19 = 2'b00;
    assign _94 = 2'b10;
    assign _66 = calc_position < _45;
    assign _67 = ~ _66;
    assign _95 = _67 ? _94 : _20;
    assign _43 = 32'b00000000000000000000000001100100;
    assign _89 = calc_position - _43;
    assign _31 = ~ _30;
    assign _90 = _31 ? _89 : _87;
    assign _86 = calc_position + _43;
    assign _30 = calc_position[31:31];
    assign _87 = _30 ? _86 : calc_position;
    assign _28 = calc_position < _43;
    assign _29 = ~ _28;
    assign _91 = _29 ? _90 : _87;
    assign _80 = 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;     
    assign _6 = clk;
    assign _8 = din;
    always @(posedge _6) begin
        if (_10)
            _81 <= _80;
        else
            _81 <= _8;
    end
    assign _82 = _81[31:0];
    assign _83 = calc_position + _82;
    assign _78 = 32'b00000000000000000000000000110010;
    assign _10 = rst;
    assign _79 = _10 ? _78 : calc_position;
    assign _84 = _13 ? _83 : _79;
    always @* begin
        case (_20)
        2'b00:
            _92 <= _84;
        2'b01:
            _92 <= _91;
        default:
            _92 <= calc_position;
        endcase
    end
    assign _11 = _92;
    always @(posedge _6) begin
        calc_position <= _11;
    end
    assign _44 = calc_position < _43;
    assign _96 = _44 ? _95 : _20;
    assign _35 = 2'b01;
    assign _13 = din_valid;
    assign _93 = _13 ? _35 : _20;
    always @* begin
        case (_20)
        2'b00:
            _97 <= _93;
        2'b01:
            _97 <= _96;
        2'b10:
            _97 <= _19;
        default:
            _97 <= _20;
        endcase
    end
    assign _14 = _97;
    always @(posedge _6) begin
        if (_10)
            _20 <= _19;
        else
            _20 <= _14;
    end
    always @* begin
        case (_20)
        2'b10:
            _105 <= _104;
        default:
            _105 <= calc_num_loops_a;
        endcase
    end
    assign _15 = _105;
    always @(posedge _6) begin
        if (_10)
            calc_num_loops_a <= _45;
        else
            calc_num_loops_a <= _15;
    end
    assign _17 = control;
    assign _107 = _17[3:3];
    assign _108 = _107 ? calc_num_loops_b : calc_num_loops_a;
    assign _106 = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    assign _109 = { _106,
                    _108 };
    assign dout = _109;
    assign dout_valid = _13;

endmodule
module coprocessor_top (
    control,
    din_valid,
    din,
    rst,
    clk,
    dout,
    dout_valid
);

    input [4:0] control;
    input din_valid;
    input [127:0] din;
    input rst;
    input clk;
    output [127:0] dout;
    output dout_valid;

    wire _14;
    wire [4:0] _3;
    wire _5;
    wire [127:0] _7;
    wire _9;
    wire _11;
    wire [128:0] _13;
    wire [127:0] _15;
    assign _14 = _13[128:128];
    assign _3 = control;
    assign _5 = din_valid;
    assign _7 = din;
    assign _9 = rst;
    assign _11 = clk;
    coprocessor
        coprocessor
        ( .clk(_11),
          .rst(_9),
          .din(_7),
          .din_valid(_5),
          .control(_3),
          .dout(_13[127:0]),
          .dout_valid(_13[128:128]) );
    assign _15 = _13[127:0];
    assign dout = _15;
    assign dout_valid = _14;

endmodule
