//求RGB分量的最小值
//即求出暗通道
module DCP_rgb_dark
(
    input           pixelclk     ,
    input           reset_n      ,
    input   [23:0]  i_rgb        ,
    input           i_data_valid ,  

    output  [ 7:0]  o_dark       ,
    output          o_data_valid
);

reg             idata_valid_r,idata_valid_r0;

wire    [7:0]   r;
wire    [7:0]   g;
wire    [7:0]   b;
reg     [7:0]   b_r;
reg     [7:0]   dark_r;
reg     [7:0]   dark_r1;
        
always @(posedge pixelclk) begin
    idata_valid_r   <= i_data_valid;
    idata_valid_r0  <= idata_valid_r;    
    b_r             <= b;
end

assign r = i_rgb[23:16];
assign g = i_rgb[15:8];
assign b = i_rgb[7:0];
                
assign o_dark       = dark_r1;  
assign o_data_valid = idata_valid_r0;

// 遍历每一个像素点
always @(posedge pixelclk) begin
    if(!reset_n) 
        dark_r <= 8'b0;
    else if(i_data_valid == 1'b1) begin
        if(r > g) 
            dark_r <= g; 
        else 
            dark_r <= r;  
    end
    else 
        dark_r <= 8'b0;
end

always @(posedge pixelclk) begin
    if(!reset_n) 
        dark_r1 <= 8'b0;
    else if(idata_valid_r == 1'b1) begin
        if(b_r > dark_r) 
            dark_r1 <= dark_r; 
        else 
            dark_r1 <= b_r;   
    end
    else 
        dark_r1 <= 8'b0;
end  

endmodule