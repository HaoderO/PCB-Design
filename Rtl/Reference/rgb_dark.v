//求RGB分量的最小值
//即求出暗通道
module rgb_dark
(
    input           pixelclk,//
    input           reset_n ,//
    input  [23:0]   i_rgb   ,//
    input           i_hsync ,//
    input           i_vsync ,//
    input           i_de    ,//

    output [ 7:0]   o_dark  ,//暗通道图像数据
    output          o_hsync ,//
    output          o_vsync ,//                                                                                                
    output          o_de                                                                                               
);
  
reg         hsync_r,hsync_r0;//数据寄存，该模块处理数据耗费两个时钟周期
reg         vsync_r,vsync_r0;//同上
reg         de_r,de_r0;      //同上
wire [7:0]  r;//
wire [7:0]  g;//
wire [7:0]  b;//
reg  [7:0]  b_r;
reg  [7:0]  dark_r;
reg  [7:0]  dark_r1;
       
always @(posedge pixelclk) begin//输入输出的打拍操作
  hsync_r  <= i_hsync;
  vsync_r  <= i_vsync;
  de_r     <= i_de; 
  hsync_r0 <= hsync_r;
  vsync_r0 <= vsync_r;
  de_r0    <= de_r;
  b_r      <= b;
end

//将RGB888模式的原始图像数据拆分为R G B三个颜色通道
assign r        = i_rgb[23:16];
assign g        = i_rgb[15:8];
assign b        = i_rgb[7:0];

//就是输出
assign o_hsync  = hsync_r0;
assign o_vsync  = vsync_r0;
assign o_de     = de_r0;
assign o_dark   = dark_r1;  
//-------------------------------------------------------------
// r g b dark
//-------------------------------------------------------------
always @(posedge pixelclk) begin
  if(!reset_n) dark_r<= 8'b0;
  else if(i_de==1'b1) begin
    if(r>g) dark_r<= g; 
    else dark_r<= r;  
  end
  else dark_r<= 8'b0;
end

always @(posedge pixelclk) begin
  if(!reset_n) dark_r1<= 8'b0;
  else if(de_r==1'b1) begin
  if(b_r>dark_r) dark_r1<= dark_r; 
    else dark_r1<= b_r;   
  end
  else dark_r1<= 8'b0;
end  

endmodule