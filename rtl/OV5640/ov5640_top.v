module ov5640_top
#(
    parameter CMOS_H_PIXEL  = 12'd640       ,   //CMOS输出宽度
    parameter CMOS_V_PIXEL  = 12'd480       ,   //CMOS输出高度
    parameter H_DISP        = 12'd480       ,   //图像宽度
    parameter V_DISP        = 12'd272           //图像高度
)
(
    input   wire            clk_24m         ,   //时钟
    input   wire            rst_n           ,   //复位
    //cmos 
    output  wire            cmos_xclk       ,   //CMOS 驱动时钟
    output  reg             cmos_rst_n      ,   //CMOS 复位信号
    output  wire            cmos_pwdn       ,   //CMOS 休眠模式
    input   wire            cmos_pclk       ,   //CMOS 数据时钟
    input   wire            cmos_href       ,   //CMOS 行同步
    input   wire            cmos_vsync      ,   //CMOS 场同步
    input   wire    [ 7:0]  cmos_data       ,   //CMOS 像素数据
    output  wire            cmos_scl        ,   //CMOS SCCB_SCL
    inout   wire            cmos_sda        ,   //CMOS SCCB_SDA
    //RGB 
    output  wire            RGB_vld         ,   //RGB数据使能
    output  wire    [15:0]  RGB_data        ,   //RGB数据
    output  wire    [ 7:0]  FPS_rate            //FPS帧率
);

reg     [18:0]              delay_cnt       ;
wire                        sccb_vld        ;
wire                        sccb_en         ;
wire    [23:0]              sccb_data       ;        
wire                        sccb_done       ;
wire                        sccb_dri_clk    ;
wire                        sccb_cfg_done   ;

//cmos简单信号
//cmos_xclk要求24Mhz
assign cmos_xclk  = clk_24m;

//关闭休眠模式
assign cmos_pwdn  = 1'b0;

//延时计数器
always @(posedge clk_24m or negedge rst_n) begin
    if(!rst_n)
        delay_cnt <= 'b0;
    else if(delay_cnt <= 504000)
        delay_cnt <= delay_cnt + 1'b1;                    
end

//复位信号，至少延时1ms
always @(posedge clk_24m or negedge rst_n) begin
    if(!rst_n)
        cmos_rst_n <= 1'b0;    
    else if(delay_cnt==240000)
        cmos_rst_n <= 1'b1;
end

//SCCB驱动和配置
//至少延时20ms再进行SCCB配置
assign sccb_vld = delay_cnt == 504001;

//SCCB寄存器配置
sccb_ov5640_cfg
#(
    .CMOS_H_PIXEL           (CMOS_H_PIXEL           ),  //CMOS输出宽度
    .CMOS_V_PIXEL           (CMOS_V_PIXEL           )   //CMOS输出高度
)
u_sccb_ov5640_cfg
(
    .clk                    (sccb_dri_clk           ),  //时钟，1Mhz
    .rst_n                  (rst_n                  ),  //复位，低电平有效
    .sccb_vld               (sccb_vld               ),  //SCCB配置有效
    .sccb_done              (sccb_done              ),  //SCCB寄存器配置完成信号
    .sccb_en                (sccb_en                ),  //SCCB触发执行信号   
    .sccb_data              (sccb_data              ),  //SCCB要配置的地址与数据(高8位地址,低8位数据)
    .sccb_cfg_done          (sccb_cfg_done          )   //SCCB全部寄存器配置完成信号
);

//SCCB时序驱动
sccb 
#(
    .DEVICE_ID              (8'h78                  ),  //器件ID
    .CLK                    (26'd24_000_000         ),  //24Mhz
    .SCL                    (18'd250_000            )   //250Khz
)
u_sccb
(       
    .clk                    (cmos_xclk              ),  //时钟   
    .rst_n                  (rst_n                  ),  //复位，低电平有效
    //SCCB input  
    .sccb_en                (sccb_en                ),  //SCCB触发信号
    .sccb_addr              (sccb_data[23:8]        ),  //SCCB器件内地址  
    .sccb_data              (sccb_data[7:0]         ),  //SCCB要写的数据
    //SCCB output  
    .sccb_done              (sccb_done              ),  //SCCB一次操作完成   
    .sccb_scl               (cmos_scl               ),  //SCCB的SCL时钟信号
    .sccb_sda               (cmos_sda               ),  //SCCB的SDA数据信号
    //dri_clk  
    .sccb_dri_clk           (sccb_dri_clk           )   //驱动SCCB操作的驱动时钟，1Mhz
);

//获得摄像头数据，转RGB565并裁剪分辨率
cmos_capture
#(
    .CMOS_H_PIXEL           (CMOS_H_PIXEL           ),  //CMOS输出宽度
    .CMOS_V_PIXEL           (CMOS_V_PIXEL           ),  //CMOS输出高度
    .H_DISP                 (H_DISP                 ),  //图像宽度
    .V_DISP                 (V_DISP                 )   //图像高度
)
u_cmos_capture
(
    .clk_24m                (clk_24m                ),  //24Mhz
    .cmos_pclk              (cmos_pclk              ),  //cmos数据像素时钟
    .rst_n                  (rst_n & sccb_cfg_done  ),  //复位，低电平有效
    //cmos    
    .cmos_href              (cmos_href              ),  //CMOS 行同步
    .cmos_vsync             (cmos_vsync             ),  //CMOS 场同步
    .cmos_data              (cmos_data              ),  //CMOS 像素数据
    //RGB    
    .RGB_vld                (RGB_vld                ),  //RGB数据使能
    .RGB_data               (RGB_data               ),  //RGB数据
    .FPS_rate               (FPS_rate               )   //FPS帧率
);

endmodule
