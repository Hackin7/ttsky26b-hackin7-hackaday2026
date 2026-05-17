/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module palette (
    input  wire [2:0] color_index,
    output wire [5:0] rrggbb
);

  reg [5:0] palette[7:0];

  initial begin
    palette[0] = 6'b000000;  // transparent (unused on draw)
    palette[1] = 6'b000000;  // black (cat)
    palette[2] = 6'b101010;  // grey (hat)
    palette[3] = 6'b101100;  // brown (backpack)
    palette[4] = 6'b010100;  // green (bedroll)
    palette[5] = 6'b001011;  // blue (sweat)
    palette[6] = 6'b111111;  // white (eyes, whiskers)
    palette[7] = 6'b010101;  // dark grey (outlines)
  end

  assign rrggbb = palette[color_index];

endmodule
