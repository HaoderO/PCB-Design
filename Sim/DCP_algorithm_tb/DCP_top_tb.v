`timescale 1ns/1ps
module DCP_top_tb;

  // Parameters

  // Ports
  reg  pixelclk = 0;
  reg  reset_n = 0;
  reg [23:0] i_rgb;
  reg  i_data_valid = 0;
  wire [23:0] o_defog_rgb;
  wire  o_data_valid;

  DCP_top DCP_top_dut 
  (
    .pixelclk (pixelclk ),
    .reset_n (reset_n ),
    .i_rgb (i_rgb ),
    .i_data_valid (i_data_valid ),
    .o_defog_rgb (o_defog_rgb ),
    .o_data_valid  ( o_data_valid)
  );

  initial begin
    begin
        i_rgb = 24'd0;
        #100
        reset_n = 1;
        i_data_valid = 1;
    end
  end

  always #5 pixelclk = ! pixelclk ;

always @(negedge reset_n or posedge pixelclk)
    if (reset_n == 1'b0) 
        i_rgb <= 24'd0;
    else
        i_rgb <= {$random}; //产生随机数

endmodule
