module Atmo_light 
(
    input   wire                sys_clk     ,
    input   wire                sys_rst_n   ,
    input   wire    [23:0]      picture_data        ,//RGB332
    input   wire    [7:0]       dark_ch_data         

    output  wire    [7:0]   A         
);

wire    [7:0]   r_rgb;//RGB888
wire    [7:0]   g_rgb;
wire    [7:0]   b_rgb;
wire    [7:0]   rg_max;    //R G中的最大值   
wire    [7:0]   rgb_max;    //R G B中的最大值  

//获取三通道最大值

assign r_rgb = picture_data[23:16]; 
assign g_rgb = picture_data[15:8]; 
assign b_rgb = picture_data[7:0]; 

assign rg_max = (r_rgb <= g_rgb) ? r_rgb : g_rgb;
assign rgb_max = (rg_max <= b_rgb) ? rg_max : b_rgb;

endmodule