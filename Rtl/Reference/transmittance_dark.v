//求暗通道最大值和透射率
module transmittance_dark
(
    input           pixelclk       ,
    input           reset_n        ,
    input  [ 7:0]   i_dark         ,//暗通道图像数据
    input           i_hsync        ,
    input           i_vsync        ,
    input           i_de           ,

    output [ 7:0]   o_dark_max     ,//暗通道图像的最大像素值
    output [ 7:0]   o_transmittance,  //透射率
    output          o_hsync        ,
    output          o_vsync        ,                                                                                                  
    output          o_de                                                                                                       
);

/****************************************************************************/
//以下参数均为小数，为避免浮点运算，将原公式整体扩大256倍

//parameter X0 = 8'd80;// 0.3 = 80/256 ？？？这是啥？？？

//晴朗的天气看远处也是雾蒙蒙的，因为空气也会折射一部分光线
//因此引入去雾保留因子，保留一部分"雾气"，让去雾后的图像更加真实
//parameter W0 = 8'd166;//0.65 = 166/256 去雾保留因子，为1时完全去雾

//“为了表示透明体透过光的程度，通常用透过后的光通量与入射光通量 之比τ来表征物体的透光性质，τ称为光透射率。”——度娘
//显然透射率的取值范围是0到1
//暗通道像素值也即灰度值0（黑）到255（白）
//其值越小，表明环境光越暗，即认为雾的浓度越大，对应的透射率应越低
//DCP算法图像复原公式中，透射率在分母J=(I-A(1-t))/t，不能为零，故为其设定一个下限
parameter T0 = 8'd26;// 0.1 = 26/255，即t=0.1
/****************************************************************************/
  
reg           hsync_r,hsync_r0,hsync_r1;
reg           vsync_r,vsync_r0,vsync_r1;
reg           de_r,de_r0,de_r1;
wire  [7:0]   dark_gray;
reg   [7:0]   r_i_dark ;
reg   [7:0]   max_dark;
reg   [7:0]   max_dark_data;
wire          vsync_pos;//posedge of vsync
wire          vsync_neg;//negedge of vsync
wire          hsync_pos; 
reg   [7:0]   transmittance_img;
reg   [7:0]   transmittance;
reg   [7:0]   transmittance_result;
       
always @(posedge pixelclk) begin//输入打3拍
    hsync_r <= i_hsync;
    vsync_r <= i_vsync;
    de_r    <= i_de;
    r_i_dark<= i_dark;
    
    hsync_r0 <= hsync_r;
    vsync_r0 <= vsync_r;
    de_r0    <= de_r;
    
    hsync_r1 <= hsync_r0;
    vsync_r1 <= vsync_r0;
    de_r1    <= de_r0;
end

assign dark_gray        = r_i_dark;//gray
//assign vsync_neg      = ((!i_vsync) & vsync_r)?1'b1:1'b0;
//assign vsync_pos      = (i_vsync & (!vsync_r))?1'b1:1'b0;
//assign hsync_pos      = (i_hsync & (!hsync_r))?1'b1:1'b0;
                
assign o_hsync          = hsync_r1            ;
assign o_vsync          = vsync_r1            ;
assign o_de             = de_r1               ;
assign o_transmittance  = transmittance_result;  
assign o_dark_max       = max_dark_data       ;
//-------------------------------------------------------------
// max dark
// max_dark_data
//-------------------------------------------------------------
always @(posedge pixelclk) begin
    if(!reset_n) begin
        max_dark <= 8'b0; //赋初值
        max_dark_data <= 8'b0;  //赋初值
    end
    else if(vsync_pos==1'b1) 
        max_dark <= dark_gray;  //场同步信号为高电平，将暗通道数据给暗通道最大值
    else if(de_r == 1'b1) begin
        if(dark_gray > max_dark)  //当输入数据有效时，比较当前的暗通道最大值和暗通道像素值
            max_dark <= dark_gray;  //若新输入的暗通道值大于当前的最大值，则将其设为新的最大值
    else 
        max_dark <= max_dark; //否则最大值保持不变
        max_dark_data <= max_dark;
    end
//  else if(vsync_neg == 1'b1) begin
//  else if(hsync_pos == 1'b1) begin
//    max_dark_data <= max_dark;
//  max_dark<= 8'b0;
//  end 
end
//-------------------------------------------------------------
// t1 img
// max_dark_data 越大，越有可能是雾
// t(x)=1−w*min(minI(y)/A)
//-------------------------------------------------------------

always @(posedge pixelclk) begin
    if(!reset_n) begin
        transmittance     <= 8'd0;  //透射率赋初值
        transmittance_img <= 8'd0;
    end
    else if((max_dark_data > 8'd160) && (max_dark_data < 8'd170)) begin
        transmittance     <= dark_gray;                     //w=1
        transmittance_img <= 8'd255 - transmittance;
    end
/**********************************************************************************************************************/
//以暗通道像素最大值衡量雾霾浓度大小（因为无雾图像的暗通道像素值都很小，都接近于零）
//暗通道像素值的最大值越大，越有可能是有雾图，故取得w越大
//并以此来动态调节去雾保留因子（思想见博客园精简、优选1 Page29）
// t=1-[(w*Idark)/A]，设A=255，则255×t=255×(1-w*Idark/255)，即255×t=255-w*Idark
/**********************************************************************************************************************/
    else if((max_dark_data > 8'd170) && (max_dark_data < 8'd180)) begin
//每向右移一位相当于除2：dark_gray/2 + dark_gray/4 + dark_gray/8 + dark_gray/16 = dark_gray×(15/16) = 0.9375dark_gray
        transmittance     <= (dark_gray[7:1] + dark_gray[7:2] + dark_gray[7:3] + dark_gray[7:4]);//w=0.9375
        transmittance_img <= 8'd255 - transmittance;
    end
    else if((max_dark_data > 8'd180) && (max_dark_data < 8'd190)) begin
 //每向右移一位相当于除2：dark_gray/2 + dark_gray/4 + dark_gray/8 = dark_gray×(7/8) = 0.875dark_gray
        transmittance     <= (dark_gray[7:1] + dark_gray[7:2] + dark_gray[7:3]);//w=0.875
        transmittance_img <= 8'd255 - transmittance;
    end
    else if((max_dark_data > 8'd190) && (max_dark_data < 8'd200)) begin
//每向右移一位相当于除2：dark_gray/2 + dark_gray/4 + dark_gray/16 = dark_gray×(13/16) = 0.8125dark_gray
        transmittance     <= (dark_gray[7:1] + dark_gray[7:2] + dark_gray[7:4]);//w=0.8125
        transmittance_img <= 8'd255 - transmittance;
    end
    else if((max_dark_data > 8'd200) && (max_dark_data < 8'd210)) begin
//每向右移一位相当于除2：dark_gray/2 + dark_gray/4 + dark_gray/32 = dark_gray×(25/32) = 0.78125dark_gray
        transmittance     <= (dark_gray[7:1] + dark_gray[7:2] + dark_gray[7:5]);//w=0.78125
        transmittance_img <= 8'd255 - transmittance;
    end
    else if((max_dark_data > 8'd210) && (max_dark_data < 8'd220)) begin
//每向右移一位相当于除2：dark_gray/2 + dark_gray/4 = dark_gray×(3/4) = 0.75dark_gray
        transmittance     <= (dark_gray[7:1] + dark_gray[7:2]);//w=0.75
        transmittance_img <= 8'd255 - transmittance;
    end
    else if((max_dark_data > 8'd220) && (max_dark_data < 8'd230)) begin
//每向右移一位相当于除2：dark_gray/2 + dark_gray/8 + dark_gray/16 + dark_gray/32 = dark_gray×(23/32) = 0.71875dark_gray
        transmittance     <= (dark_gray[7:1] + dark_gray[7:3] + dark_gray[7:4] + dark_gray[7:5]);//w=0.71875
        transmittance_img <= 8'd255 - transmittance;
    end
    else if((max_dark_data > 8'd230) && (max_dark_data < 8'd240)) begin
//每向右移一位相当于除2：dark_gray/2 + dark_gray/8 + dark_gray/16 = dark_gray×(11/16) = 0.6875dark_gray
        transmittance     <= (dark_gray[7:1] + dark_gray[7:3] + dark_gray[7:4]);//w=0.6875
        transmittance_img <= 8'd255 - transmittance;
    end
    else if(max_dark_data > 8'd240) begin
//每向右移一位相当于除2：dark_gray/2 + dark_gray/8 + dark_gray/64 = dark_gray×(11/64) = 0.640625dark_gray
        transmittance     <= (dark_gray[7:1] + dark_gray[7:3] + dark_gray[7:6]);//w=0.640625
        transmittance_img <= 8'd255 - transmittance;
    end
    else begin
        transmittance     <= 8'd0;
        transmittance_img <= 8'd0;
    end
end
//-------------------------------------------------------------
// t2 img
//-------------------------------------------------------------
always @(posedge pixelclk) begin
    if(!reset_n) 
        transmittance_result <= 8'b0;
    else if(transmittance_img > T0) 
        transmittance_result <= transmittance_img; 
    else 
        transmittance_result <= T0; 
end

endmodule