module defogging
(//不特别注明，默认都是wire型
    input  wire         pixelclk       ,  
    input  wire         reset_n        ,  
    input  wire [23:0]  i_rgb          ,  //原图
    input  wire [7:0]   i_transmittance,  //透射率（注意：已经放大了256倍）
    input  wire [7:0]   dark_max       ,  //暗通道最大值
    input  wire         i_hsync        ,  
    input  wire         i_vsync        ,  
    input  wire         i_de           ,    

    output wire [23:0]  o_defogging    ,  //去雾图像输出
    output wire         o_hsync        ,  
    output wire         o_vsync        ,                                                                                                    
    output wire         o_de                                                                                                       
);
     
parameter DEVIDER = 255*16;
     
reg           hsync_r,hsync_r0;
reg           vsync_r,vsync_r0;
reg           de_r,de_r0;
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

assign  r_flag = (i_de == 1'b1 (&& mult2 > mult_r)) ? 1'b1 : 1'b0 ;
assign  g_flag = (i_de == 1'b1 (&& mult2 > mult_g)) ? 1'b1 : 1'b0 ;
assign  b_flag = (i_de == 1'b1 (&& mult2 > mult_b)) ? 1'b1 : 1'b0 ;
      
always @(posedge pixelclk) begin//输入数据打拍

  //行、场同步信号，使能信号打两拍
    hsync_r   <= i_hsync;
    vsync_r   <= i_vsync;
    hsync_r0  <= hsync_r;
    vsync_r0  <= vsync_r;
    de_r      <= i_de;
    de_r0     <= de_r; 

    //原始图像数据打四拍
    rgb_r0    <= i_rgb;
    rgb_r1    <= rgb_r0;
    rgb_r2    <= rgb_r1;
    rgb_r3    <= rgb_r2;
end

assign r        = rgb_r3[23:16];
assign g        = rgb_r3[15:8];
assign b        = rgb_r3[7:0];

assign transmittance_gray = i_transmittance;//transmittance gray
              
assign o_hsync  = hsync_r0;
assign o_vsync  = vsync_r0;
assign o_de     = de_r0;

assign o_defogging   = {r_r[19:12],g_r[19:12],b_r[19:12]};  //取各三个颜色通分量的高八位

/*
always @(posedge pixelclk or negedge reset_n) begin
  if(!reset_n) begin
   r_r <= 24'b0;
   g_r <= 24'b0;
   b_r <= 24'b0;
  end
  else begin
    r_r <= (r*255-(255-transmittance_gray)*dark_max)*(255/transmittance_gray);
  g_r <= (g*255-(255-transmittance_gray)*dark_max)*(255/transmittance_gray);
  b_r <= (b*255-(255-transmittance_gray)*dark_max)*(255/transmittance_gray);
  end
end
*/

// t(x)=1−wmin(minI(y)/A)
// 图像复原公式J=(I-A(1-t))/t
always @(posedge pixelclk or negedge reset_n) begin
    if(!reset_n) begin
        r_r    <= 'b0;
        g_r    <= 'b0;
        b_r    <= 'b0;
        mult1  <= 12'b0;
        mult2  <= 16'b0;
        mult_r <= 16'b0;
        mult_g <= 16'b0;
        mult_b <= 16'b0;
    end
    else begin
      // mult1 = 255*16/255*t,t的范围是0.1到1，mult1的范围是16到160
        mult1  <= DEVIDER/transmittance_gray;

      // mult2 = (255-t*255)*Idark = 255*(1-t)*Idark
      //t的范围是0.1到1，Idark的范围是0到255，但实际结果应趋近于0（黑）
      //t=0.1,Idark取255时 mult2有最大值58522（二进制为16位）
        mult2  <= (255-transmittance_gray)*dark_max;

        //mult_r <= r*255;
        //mult_g <= g*255;
        //mult_b <= b*255;
        mult_r <= (r << 8);//对三个颜色分量均扩大256倍，保持复原公式结果不变
        mult_g <= (g << 8);
        mult_b <= (b << 8);
    //r_r <= (mult_r-mult2)*mult1;
    //g_r <= (mult_g-mult2)*mult1;
    //b_r <= (mult_b-mult2)*mult1;

    //由图像复原公式得：   
    //J(r)=(255*r - 255*(1-t)*Idark)*255*16/255*t
    //J(g)=(255*g - 255*(1-t)*Idark)*255*16/255*t
    //J(b)=(255*b - 255*(1-t)*Idark)*255*16/255*t
    //即J=255×[I-A(1-t)]×(16/t)
        r_r <= (r_flag == 1'b1) ? {r,12'b0} : (mult_r-mult2)*mult1 ;
        g_r <= (g_flag == 1'b1) ? {g,12'b0} : (mult_g-mult2)*mult1 ;
        b_r <= (b_flag == 1'b1) ? {b,12'b0} : (mult_b-mult2)*mult1 ;
    end
end

endmodule