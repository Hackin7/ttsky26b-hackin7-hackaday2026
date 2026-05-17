/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

parameter LOGO_SIZE = 48;
parameter DISPLAY_WIDTH = 640;
parameter DISPLAY_HEIGHT = 480;

module tt_um_hackin7_tbd (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  wire hsync;
  wire vsync;
  reg [1:0] R;
  reg [1:0] G;
  reg [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  wire cfg_tile = ui_in[0];
  wire cfg_cycle = ui_in[1];

  assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uio_out = 0;
  assign uio_oe  = 0;

  wire _unused_ok = &{ena, ui_in[7:2], uio_in};

  reg [9:0] prev_y;

  hvsync_generator vga_sync_gen (
      .clk(clk),
      .reset(~rst_n),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(video_active),
      .hpos(pix_x),
      .vpos(pix_y)
  );

  reg [9:0] logo_left;
  reg [9:0] logo_top;
  reg dir_x;
  reg dir_y;

  wire [2:0] pixel_color;
  reg [2:0] bounce_shift;
  wire [2:0] draw_color;
  wire [5:0] color;

  wire [9:0] x = pix_x - logo_left;
  wire [9:0] y = pix_y - logo_top;
  wire in_sprite = (x < LOGO_SIZE) && (y < LOGO_SIZE);
  wire logo_pixels = cfg_tile | in_sprite;
  wire pixel_on = pixel_color != 3'd0;

  bitmap_rom rom1 (
      .x(x[5:0]),
      .y(y[5:0]),
      .color_idx(pixel_color)
  );

  assign draw_color = cfg_cycle ? (pixel_color + bounce_shift) : pixel_color;

  palette palette_inst (
      .color_index(draw_color),
      .rrggbb(color)
  );

  always @(posedge clk) begin
    if (~rst_n) begin
      R <= 0;
      G <= 0;
      B <= 0;
    end else begin
      R <= 0;
      G <= 0;
      B <= 0;
      if (video_active && logo_pixels && pixel_on) begin
        R <= color[5:4];
        G <= color[3:2];
        B <= color[1:0];
      end
    end
  end

  always @(posedge clk) begin
    if (~rst_n) begin
      logo_left <= 296;
      logo_top <= 216;
      dir_y <= 0;
      dir_x <= 1;
      bounce_shift <= 0;
    end else begin
      prev_y <= pix_y;
      if (pix_y == 0 && prev_y != pix_y) begin
        logo_left <= logo_left + (dir_x ? 1 : -1);
        logo_top  <= logo_top + (dir_y ? 1 : -1);
        if (logo_left - 1 == 0 && !dir_x) begin
          dir_x <= 1;
          bounce_shift <= bounce_shift + 1;
        end
        if (logo_left + 1 == DISPLAY_WIDTH - LOGO_SIZE && dir_x) begin
          dir_x <= 0;
          bounce_shift <= bounce_shift + 1;
        end
        if (logo_top - 1 == 0 && !dir_y) begin
          dir_y <= 1;
          bounce_shift <= bounce_shift + 1;
        end
        if (logo_top + 1 == DISPLAY_HEIGHT - LOGO_SIZE && dir_y) begin
          dir_y <= 0;
          bounce_shift <= bounce_shift + 1;
        end
      end
    end
  end

endmodule
