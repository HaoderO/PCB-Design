module static_dehazing
(
   input    wire           board_clk      ,
   input    wire           rx             ,    
   input    wire           sys_rst_n      ,     

   output   wire           hsync          ,
   output   wire           vsync          ,
   output   wire [7:0]     rgb_red        ,
   output   wire [7:0]     rgb_green      ,
   output   wire [7:0]     rgb_blue       ,
   output   wire  [23:0]    dark_ch_pic,
   output   wire           vga_driver_clk ,
   output   wire           rgb_blk        
);

//tips：参考系统框图定义内部连线，能有效避免连线错误
   wire           clk_25M;
   wire           clk_50M;
   wire           rx_flag;
   wire  [7:0]    pix_data;
   wire  [7:0]    rx_out;
   wire  [9:0]    pix_x;
   wire  [9:0]    pix_y;

   wire  [2:0]    rgb_r;
   wire  [2:0]    rgb_g;
   wire  [1:0]    rgb_b;

//VGA模块不支持RGB332故通过补充R G B三个通道的低位，将RGB332转换为RGB888
//高三位也是包含了图像数据的重要信息
assign rgb_red    = {rgb_r , 5'b0};
assign rgb_green  = {rgb_g , 5'b0};                                        
assign rgb_blue   = {rgb_b , 6'b0};
assign dark_ch_pic   = {rgb_red , rgb_green , rgb_blue};

//使用的VGA模块需要一路驱动时钟，与640×480对应
assign vga_driver_clk = clk_25M;

pll_ip u0
   (
      .inclk0        (board_clk  ), //50MHz

      .c0            (clk_25M    ), //25MHz
      .c1            (clk_50M    )  //50MHz
   );
   
uart_rx u1
   (
      .sys_clk       (clk_50M    ),
      .sys_rst_n     (sys_rst_n  ),
      .rx            (rx         ),

      .para_out      (rx_out     ),
      .valid_flag    (rx_flag    )   
   );

vga_ctrl u2
   (
      .vga_clk       (clk_25M    ), 
      .sys_rst_n     (sys_rst_n  ), 
      .pix_data      (pix_data   ), 

      .hsync         (hsync      ), 
      .vsync         (vsync      ), 
      .pix_x         (pix_x      ), 
      .pix_y         (pix_y      ), 
      .vga_rgb       ({rgb_r, rgb_g, rgb_b}), 
      .vga_blk       (rgb_blk    )
   );
   
vga_pic u3
   (
      .sys_clk       (clk_50M    ),
      .vga_clk       (clk_25M    ),
      .sys_rst_n     (sys_rst_n  ),
      .pix_x         (pix_x      ),
      .pix_y         (pix_y      ),
      .pic_data_in   (rgb_min     ),
//      .rx_valid_flag (    ),

      .pix_data      (pix_data   )   //RGB565
   );

dark_channel u4
   (
      .sys_clk       (rx_flag    ),
      .sys_rst_n     (sys_rst_n  ),
      .picture_data  (rx_out     ),

      .I_dark       (rgb_min    )
   );

endmodule
