module vga_pic
(
   input    wire           sys_clk        ,//50M
   input    wire           vga_clk        ,//25M
   input    wire           sys_rst_n      ,
   input    wire  [9:0]    pix_x          ,//有效显示区域的X坐标
   input    wire  [9:0]    pix_y          ,//有效显示区域的Y坐标
   input    wire  [7:0]    pic_data_in    ,
   input    wire           rx_valid_flag  ,
   
   output   wire  [7:0]    pix_data          //RGB332
);

   parameter     h_valid   = 10'd640;
   parameter     v_valid   = 10'd480;
   parameter     pic_v     = 10'd128;
   parameter     pic_h     = 10'd128;
   //parameter     pic_size  = pic_h * pic_v;
   parameter     pic_size  = 20'd16384;

   wire           rd_en          ;
   wire  [7:0]    pic_data       ;
   //reg   [7:0]    bkg_data       ;//背景色,彩色间条已省略
   reg            pic_valid      ;
   reg   [13:0]   wr_addr        ;
   reg   [13:0]   rd_addr        ;
   
   ram_ip	u0
   (
      .data       (pic_data_in   ),
      .inclock    (sys_clk       ),
      .outclock   (vga_clk       ),
      .rdaddress  (rd_addr       ),
      .wraddress  (wr_addr       ),
      .wren       (rx_valid_flag ),
      .q          (pic_data      )
   );
   
//背景色设为白色
assign pix_data = (pic_valid == 1'b1) ? (pic_data) : 8'b1111_1111;

assign rd_en = ((pix_x >= (((h_valid - pic_h)/2) - 1'b1)) && 
                (pix_x < ((((h_valid - pic_h)/2) + pic_h) - 1'b1)) && 
                (pix_y >= ((v_valid - pic_v)/2)) && 
                (pix_y < (((v_valid - pic_v)/2) + pic_v)));
   
always @(posedge vga_clk or negedge sys_rst_n)
   if (sys_rst_n == 1'b0)
      pic_valid <= 1'b0;
   else
      pic_valid <= rd_en;
      
always @(posedge sys_clk or negedge sys_rst_n)//注意同步时钟为系统时钟
   if (sys_rst_n == 1'b0) 
      wr_addr <= 14'd0;
   else if ((wr_addr == (pic_size - 1))&&(rx_valid_flag == 1'b1))
      wr_addr <= 14'd0;
   else if (rx_valid_flag == 1'b1)
      wr_addr <= wr_addr + 1'b1;

always @(posedge vga_clk or negedge sys_rst_n)
   if (sys_rst_n == 1'b0) 
      rd_addr <= 14'd0;
   else if (rd_addr == pic_size - 1'b1)
      rd_addr <= 14'd0;
   else if (rd_en == 1'b1)
      rd_addr <= rd_addr + 1'b1;
   
endmodule