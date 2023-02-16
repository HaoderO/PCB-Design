module dark_channel 
(
    input   wire            sys_clk     ,
    input   wire            sys_rst_n   ,
    input   wire    [23:0]   picture_data        ,//RGB332
//    input   wire            in_valid    ,


    //output  wire    [7:0]   r_dark_channel       ,
    //output  wire    [7:0]   g_dark_channel       ,    
    //output  wire    [7:0]   b_dark_channel       ,
    output  wire    [7:0]   I_dark         
//    output  reg             out_valid

);

wire    [7:0]   r_rgb;//RGB888
wire    [7:0]   g_rgb;
wire    [7:0]   b_rgb;
wire    [7:0]   rg_min;    //R G中的最小值   
wire    [7:0]   rgb_min;    //R G B中的最小值   

wire    [7:0]   taps0;
wire    [7:0]   taps1;
wire    [7:0]   taps2;
wire    [7:0]   taps01_min;//taps0 taps1中的最小值

wire    [7:0]   col0_min;//taps0 taps1 taps2中的最小值
reg     [7:0]   col1_min;
reg     [7:0]   col2_min;
wire    [7:0]   col01_min;//col0_min col1_min中的最小值


shiftreg_ip	shiftreg_ip_inst 
(
	.clock      ( sys_clk ),
	.shiftin    ( rgb_min ),
//	.shiftout   (  ),
	.taps0x     ( taps0 ),
	.taps1x     ( taps1 ),
	.taps2x     ( taps2 )
);

//获取三通道最小值
assign r_rgb = picture_data[23:16]; 
assign g_rgb = picture_data[15:8]; 
assign b_rgb = picture_data[7:0]; 

assign rg_min = (r_rgb <= g_rgb) ? r_rgb : g_rgb;
assign rgb_min = (rg_min <= b_rgb) ? rg_min : b_rgb;


//第一次最小值滤波
assign taps01_min = (taps0 <= taps1) ? taps0 : taps1;
assign col0_min = (taps01_min <= taps2) ? taps01_min : taps2;

always @(negedge sys_rst_n or posedge sys_clk)
    if (sys_rst_n == 1'b0) 
        col1_min <= 8'd0;
    else
        col1_min <= col0_min;

always @(negedge sys_rst_n or posedge sys_clk)
    if (sys_rst_n == 1'b0) 
        col2_min <= 8'd0;
    else
        col2_min <= col1_min;

//第二次最小值滤波
assign col01_min = (col0_min <= col1_min) ? col0_min : col1_min;
assign I_dark = (col01_min <= col2_min) ? col01_min : col2_min;

endmodule