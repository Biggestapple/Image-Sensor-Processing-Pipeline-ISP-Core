// Verilog netlist created by TD v4.6.96021
// Mon May  8 10:32:56 2023

`timescale 1ns / 1ps
module retinex_norm_lut  // al_ip/retinex_norm_lut.v(14)
  (
  addra,
  clka,
  doa
  );

  input [9:0] addra;  // al_ip/retinex_norm_lut.v(18)
  input clka;  // al_ip/retinex_norm_lut.v(19)
  output [7:0] doa;  // al_ip/retinex_norm_lut.v(16)


  EG_PHY_CONFIG #(
    .DONE_PERSISTN("ENABLE"),
    .INIT_PERSISTN("ENABLE"),
    .JTAG_PERSISTN("DISABLE"),
    .PROGRAMN_PERSISTN("DISABLE"))
    config_inst ();
  // address_offset=0;data_offset=0;depth=1024;width=8;num_section=1;width_per_section=8;section_size=8;working_depth=1024;working_width=9;address_step=1;bytes_in_per_section=1;
  EG_PHY_BRAM #(
    .CEAMUX("1"),
    .CEBMUX("0"),
    .CLKBMUX("0"),
    .CSA0("1"),
    .CSA1("1"),
    .CSA2("1"),
    .CSB0("1"),
    .CSB1("1"),
    .CSB2("1"),
    .DATA_WIDTH_A("9"),
    .DATA_WIDTH_B("9"),
    .MODE("SP8K"),
    .OCEAMUX("0"),
    .OCEBMUX("0"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("SYNC"),
    .RSTAMUX("0"),
    .RSTBMUX("0"),
    .WEAMUX("0"),
    .WEBMUX("0"),
    .WRITEMODE_A("NORMAL"),
    .WRITEMODE_B("NORMAL"))
    inst_1024x8_sub_000000_000 (
    .addra({addra,3'b111}),
    .clka(clka),
    .dia({open_n69,8'b00000000}),
    .doa({open_n85,doa}));

endmodule 

