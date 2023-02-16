`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/08 14:28:15
// Design Name: 
// Module Name: defogging_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module defogging_top(
	input		  pixelclk     , //像素时钟
	input         reset_n      , //复位信号
	input  [23:0] i_rgb        , //原始图像数据RGB888
	input		  i_hsync      , //行同步信号
	input		  i_vsync      , //场同步信号
	input		  i_de         , //？？？数据有效
//	input [7:0]   i_thre       , //？？阈值
	output [23:0] o_defog_rgb  , //去雾后的图像数据
	output		  o_defog_hsync, //行同步
	output		  o_defog_vsync, //场同步   
	output		  o_defog_de     //？？？数据有效         
    );

wire [ 7:0] o_dark   ;
wire		o_hsync  ;
wire		o_vsync  ;
wire		o_de     ;
wire [7: 0] dark_max ;
wire [7:0] o_transmittance ;
wire		o_hsync_1;
wire		o_vsync_1;
wire		o_de_1   ;
   	
rgb_dark u_rgb_dark(
    .pixelclk(pixelclk),
	.reset_n (reset_n ),
  	.i_rgb   (i_rgb   ),
	.i_hsync (i_hsync ),
	.i_vsync (i_vsync ),
	.i_de    (i_de    ),
		   
    .o_dark  (o_dark  ),
	.o_hsync (o_hsync ),
	.o_vsync (o_vsync ),                                                                                                  
	.o_de    (o_de    )                                                                                                
);	
	
transmittance_dark u_transmittance_dark(
    .pixelclk(pixelclk ),
	.reset_n (reset_n  ),
  	.i_dark  (o_dark   ),
	.i_hsync (o_hsync  ),
	.i_vsync (o_vsync  ),
	.i_de    (o_de     ),
//	.i_thre  (i_thre   ),

	.o_dark_max(dark_max ),
    .o_transmittance  (o_transmittance ),
	.o_hsync (o_hsync_1),
	.o_vsync (o_vsync_1),                                                                                                  
	.o_de    (o_de_1   )                                                                                               
);	

defogging u_defogging(
    .pixelclk       (pixelclk     ),
	.reset_n        (reset_n      ),
  	.i_rgb          (i_rgb        ),
	.i_transmittance(o_transmittance     ),
	.dark_max       (dark_max     ),
	.i_hsync        (o_hsync_1    ),
	.i_vsync        (o_vsync_1    ),
	.i_de           (o_de_1       ),

    .o_defogging    (o_defog_rgb  ),
	.o_hsync        (o_defog_hsync),
	.o_vsync        (o_defog_vsync),                                                                                                  
	.o_de           (o_defog_de   )                                                                                               
);
	
endmodule
