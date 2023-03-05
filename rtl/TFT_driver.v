//**************************************************************************
// *** 名称 : TFT_driver.v
// *** 作者 : xianyu_FPGA
// *** 博客 : https://www.cnblogs.com/xianyufpga/
// *** 日期 : 2019-08-10
// *** 描述 : TFT显示屏控制器，分辨率480x272
//**************************************************************************
module TFT_driver
//========================< 端口 >==========================================
(
//system --------------------------------------------
input   wire                clk                     ,   //时钟，10Mhz
input   wire                rst_n                   ,   //复位，低电平有效
//input ---------------------------------------------
output  wire                TFT_req                 ,   //输出数据请求
input   wire    [15:0]      TFT_din                 ,   //得到图像数据
//output --------------------------------------------
output  wire                TFT_clk                 ,   //TFT数据时钟
output  wire                TFT_rst                 ,   //TFT复位信号
output  wire                TFT_blank               ,   //TFT背光控制
output  wire                TFT_hsync               ,   //TFT行同步
output  wire                TFT_vsync               ,   //TFT场同步
output  wire    [15:0]      TFT_data                ,   //TFT数据输出
output  reg                 TFT_de                      //TFT数据使能
);
//========================< 参数 >==========================================
//480x272 @60 10Mhz ---------------------------------
parameter H_SYNC            = 16'd41                ;   //行同步信号
parameter H_BACK            = 16'd2                 ;   //行显示后沿
parameter H_DISP            = 16'd480               ;   //行有效数据
parameter H_FRONT           = 16'd2                 ;   //行显示前沿
parameter H_TOTAL           = 16'd525               ;   //行扫描周期
//---------------------------------------------------
parameter V_SYNC            = 16'd10                ;   //场同步信号
parameter V_BACK            = 16'd2                 ;   //场显示后沿
parameter V_DISP            = 16'd272               ;   //场有效数据
parameter V_FRONT           = 16'd2                 ;   //场显示前沿
parameter V_TOTAL           = 16'd286               ;   //场扫描周期
//========================< 信号 >==========================================
reg     [15:0]              cnt_h                   ;
wire                        add_cnt_h               ;
wire                        end_cnt_h               ;
reg     [15:0]              cnt_v                   ;
wire                        add_cnt_v               ;
wire                        end_cnt_v               ;
//==========================================================================
//==    行、场计数
//==========================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_h <= 'd0;
    else if(add_cnt_h) begin
        if(end_cnt_h)
            cnt_h <= 'd0;
        else
            cnt_h <= cnt_h + 1'b1;
    end
end

assign add_cnt_h = 'd1;
assign end_cnt_h = add_cnt_h && cnt_h==H_TOTAL-1;

always @(posedge clk or negedge rst_n) begin 
    if(!rst_n)
        cnt_v <= 'd0;
    else if(add_cnt_v) begin
        if(end_cnt_v)
            cnt_v <= 'd0;
        else
            cnt_v <= cnt_v + 1'b1;
    end
end

assign add_cnt_v = end_cnt_h;
assign end_cnt_v = add_cnt_v && cnt_v==V_TOTAL-1;
//==========================================================================
//==    TFT display
//==========================================================================
//TFT请求，提前一拍发出
assign TFT_req = (cnt_h >= H_SYNC + H_BACK - 1) && (cnt_h < H_SYNC + H_BACK + H_DISP - 1) &&
                 (cnt_v >= V_SYNC + V_BACK    ) && (cnt_v < V_SYNC + V_BACK + V_DISP    )
                 ? 1'b1 : 1'b0;

//TFT时钟
assign TFT_clk = clk;

//TFT复位
assign TFT_rst = rst_n;

//TFT背光控制
assign TFT_blank = rst_n;

//TFT行同步
assign TFT_hsync = (cnt_h < H_SYNC) ? 1'b0 : 1'b1;

//TFT场同步
assign TFT_vsync = (cnt_v < V_SYNC) ? 1'b0 : 1'b1;

//TFT数据输出
assign TFT_data = TFT_de ? TFT_din : 16'b0;

//TFT数据使能，和数据对齐
always @(posedge clk) begin
    TFT_de <= TFT_req;
end



endmodule