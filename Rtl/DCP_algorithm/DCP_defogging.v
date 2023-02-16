module DCP_defogging
(
    input         pixelclk       ,
    input         reset_n        ,
    input  [23:0] i_rgb          ,
    input  [7:0]  i_transmittance,
    input  [7:0]  i_dark_max     ,
    input         i_data_valid   ,

    output [23:0] o_defogging    ,   
    output        o_data_valid                                                                                                       
);
     
parameter DEVIDER = 255*16;

reg           idata_valid_r,idata_valid_r0;

reg   [23:0]  rgb_r0,rgb_r1,rgb_r2,rgb_r3;//delay 4 clock
wire  [7:0]   r;
wire  [7:0]   g;
wire  [7:0]   b;
wire  [7:0]   transmittance_gray;
reg   [19:0]  r_r;
reg   [19:0]  g_r;
reg   [19:0]  b_r;

wire          r_flag;
wire          g_flag;
wire          b_flag;

reg   [11:0]  mult1;
reg   [15:0]  mult2;
reg   [15:0]  mult_r;
reg   [15:0]  mult_g;
reg   [15:0]  mult_b;

assign r_flag = (i_data_valid == 1'b1 && (mult2 > mult_r)) ? 1'b1 : 1'b0;
assign g_flag = (i_data_valid == 1'b1 && (mult2 > mult_g)) ? 1'b1 : 1'b0;
assign b_flag = (i_data_valid == 1'b1 && (mult2 > mult_b)) ? 1'b1 : 1'b0;
       
always @(posedge pixelclk) begin
    idata_valid_r  <= i_data_valid; 
    idata_valid_r0 <= idata_valid_r; 

    rgb_r0 <=i_rgb;
    rgb_r1 <=rgb_r0;
    rgb_r2 <=rgb_r1;
    rgb_r3 <=rgb_r2;
end

assign r = rgb_r3[23:16];
assign g = rgb_r3[15:8];
assign b = rgb_r3[7:0];

assign transmittance_gray = i_transmittance;//transmittance gray
              
assign o_data_valid = idata_valid_r0;

assign o_defogging = {r_r[19:12],g_r[19:12],b_r[19:12]};  

always @(posedge pixelclk or negedge reset_n) begin
    if(!reset_n) begin
        r_r    <= 8'b0;
        g_r    <= 8'b0;
        b_r    <= 8'b0;
        mult1  <= 12'b0;
        mult2  <= 16'b0;
        mult_r <= 16'b0;
        mult_g <= 16'b0;
        mult_b <= 16'b0;
    end
    else begin
        mult1  <= DEVIDER/transmittance_gray;
        mult2  <= (255-transmittance_gray)*i_dark_max;
        mult_r <= (r << 8);
        mult_g <= (g << 8);
        mult_b <= (b << 8);

        r_r <= (r_flag == 1'b1) ? {r,12'b0} : (mult_r - mult2)*mult1;
        g_r <= (g_flag == 1'b1) ? {g,12'b0} : (mult_g - mult2)*mult1;
        b_r <= (b_flag == 1'b1) ? {b,12'b0} : (mult_b - mult2)*mult1;
    end
end

endmodule