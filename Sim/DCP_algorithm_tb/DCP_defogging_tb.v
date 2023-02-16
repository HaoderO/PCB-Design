module DCP_defogging_tb;

  // Parameters
  localparam  DEVIDER = 255*16;

  // Ports
  reg pixelclk = 0;
  reg reset_n = 0;
  reg [23:0] i_rgb;
  reg [7:0] i_transmittance;
  reg [7:0] i_dark_max;
  reg i_data_valid = 0;
  wire [23:0] o_defogging;
  wire o_data_valid;

  DCP_defogging 
  #(
    .DEVIDER (DEVIDER )
  )
  DCP_defogging_dut 
  (
    .pixelclk (pixelclk ),
    .reset_n (reset_n ),
    .i_rgb (i_rgb ),
    .i_transmittance (i_transmittance ),
    .i_dark_max (i_dark_max ),
    .i_data_valid (i_data_valid ),
    .o_defogging (o_defogging ),
    .o_data_valid  ( o_data_valid)
  );

  initial begin
    begin
        i_rgb = 24'd0;
        i_transmittance = 8'd242;
        i_dark_max = 8'd255;
        #100
        reset_n = 1;
        i_data_valid = 1;
    end
  end

always #5  pixelclk = ! pixelclk ;

always @(negedge reset_n or posedge pixelclk)
    if (reset_n == 1'b0) 
        i_rgb <= 24'd0;
    else
        i_rgb <= {$random}; //产生随机数
        
endmodule
