module DCP_transmittance_tb;

  // Parameters
  localparam  T0 = 8'd26;

  // Ports
  reg  pixelclk = 0;
  reg  reset_n = 0;
  reg [ 7:0] i_dark;
  reg  i_data_valid = 0;

  wire [ 7:0] o_dark_max;
  wire [ 7:0] o_transmittance;
  wire  o_data_valid;

  DCP_transmittance_dark 
  #(
    .T0 (T0 )
  )
  DCP_transmittance_dark_dut 
  (
    .pixelclk (pixelclk ),
    .reset_n (reset_n ),
    .i_dark (i_dark ),
    .i_data_valid (i_data_valid ),
    .o_dark_max (o_dark_max ),
    .o_transmittance (o_transmittance ),
    .o_data_valid  ( o_data_valid)
  );

  initial begin
    begin
        i_dark = 24'd0;
        #100
        reset_n = 1;
        i_data_valid = 1;
    end
  end

always #5  pixelclk = ! pixelclk ;

always @(negedge reset_n or posedge pixelclk)
    if (reset_n == 1'b0) 
        i_dark <= 24'd0;
    else
        i_dark <= {$random}; //产生随机数

endmodule
