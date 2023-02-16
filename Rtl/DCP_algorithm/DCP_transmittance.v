module DCP_transmittance
(
    input   wire            pixelclk       ,
    input   wire            reset_n        ,
    input   wire  [ 7:0]    i_dark         ,
    input   wire            i_data_valid   ,

    output  wire  [ 7:0]    o_dark_max     ,//暗通道图像的最大值
    output  wire  [ 7:0]    o_transmittance,//大气光  
    output  wire            o_data_valid       
);

//parameter X0 = 8'd80;
//parameter W0 = 8'd166;//0.65 去雾保留因子，等于1时完全去雾
parameter T0 = 8'd26;//0.1

reg             idata_valid_r,idata_valid_r0,idata_valid_r1;
wire  [7:0]     dark_gray;
reg   [7:0]     r_i_dark ;
reg   [7:0]     max_dark;
reg   [7:0]     max_dark_data;

reg   [7:0]     transmittance_img;
reg   [7:0]     transmittance;
reg   [7:0]     transmittance_result;
       
//打3拍
always @(posedge pixelclk) begin//同时操作多个变量必须要用begin with
    idata_valid_r  <= i_data_valid;
    idata_valid_r0 <= idata_valid_r;
    idata_valid_r1 <= idata_valid_r0;

    r_i_dark <= i_dark;
end

assign dark_gray        = r_i_dark;//gray
assign o_transmittance  = transmittance_result;  //将透射率的计算结果赋值给输出端口
assign o_dark_max       = max_dark_data       ;  //将暗通道数据的最大值赋值给输出端口
assign o_data_valid     = idata_valid_r1;

always @(posedge pixelclk) begin
    if(!reset_n) begin
        max_dark      <= 8'b0;
        max_dark_data <= 8'b0;
    end
    else if(idata_valid_r1 == 1'b1) begin
    //    max_dark <= dark_gray;
    //else if(de_r == 1'b1) begin
        if(dark_gray > max_dark) 
            max_dark <= dark_gray;
        else 
            max_dark      <= max_dark;
            max_dark_data <= max_dark;
    end
end

always @(posedge pixelclk) begin
    if(!reset_n) begin
        transmittance_img <= 0;
        transmittance     <= 0;  //透射比
    end
    else if(max_dark_data>8'd160 && max_dark_data<8'd170) begin
        transmittance<=dark_gray;                     //1
        transmittance_img <= 8'd255 - transmittance;
    end
    else if(max_dark_data>8'd170 && max_dark_data<8'd180) begin
        transmittance<=(dark_gray[7:1]+dark_gray[7:2]+dark_gray[7:3]+dark_gray[7:4]);//0.9375
        transmittance_img <= 8'd255 - transmittance;
    end
    else if(max_dark_data>8'd180 && max_dark_data<8'd190) begin
        transmittance<=(dark_gray[7:1]+dark_gray[7:2]+dark_gray[7:3]);//0.875
        transmittance_img <= 8'd255 - transmittance;
    end
    else if(max_dark_data>8'd190 && max_dark_data<8'd200) begin
        transmittance<=(dark_gray[7:1]+dark_gray[7:2]+dark_gray[7:4]);//0.8125
        transmittance_img <= 8'd255 - transmittance;
    end
    else if(max_dark_data>8'd200 && max_dark_data<8'd210) begin
        transmittance<=(dark_gray[7:1]+dark_gray[7:2]+dark_gray[7:5]);//0.78125
        transmittance_img <= 8'd255 - transmittance;
    end
    else if(max_dark_data>8'd210 && max_dark_data<8'd220) begin
        transmittance<=(dark_gray[7:1]+dark_gray[7:2]);//0.75
        transmittance_img <= 8'd255 - transmittance;
    end
    else if(max_dark_data>8'd220 && max_dark_data<8'd230) begin
        transmittance<=(dark_gray[7:1]+dark_gray[7:3]+dark_gray[7:4]+dark_gray[7:5]);//0.725
        transmittance_img <= 8'd255 - transmittance;
    end
    else if(max_dark_data>8'd230 && max_dark_data<8'd240) begin
        transmittance<=(dark_gray[7:1]+dark_gray[7:3]+dark_gray[7:4]);//0.6875
        transmittance_img <= 8'd255 - transmittance;
    end
    else if(max_dark_data>8'd240) begin
        transmittance<=(dark_gray[7:1]+dark_gray[7:3]+dark_gray[7:6]);//0.65
        transmittance_img <= 8'd255 - transmittance;
  end
  else begin
      transmittance_img<=0;
      transmittance <=0;
  end
end

always @(posedge pixelclk) begin
    if(!reset_n) 
        transmittance_result <=8'b0;
    else if(transmittance_img > T0) 
        transmittance_result <= transmittance_img; 
    else 
        transmittance_result <= T0; 
    end

endmodule