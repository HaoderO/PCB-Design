module top
#(
    parameter H_DISP    = 480       ,   //图像宽度
    parameter V_DISP    = 272           //图像高度
)
(
    input               sys_clk     ,   //系统时钟，50Mhz
    input               sys_rst_n   ,   //系统复位，低电平有效
    //key 
    input   [ 1:0]      key         ,   //按键输入
    //CMOS 
    output              cmos_xclk   ,   //CMOS 驱动时钟
    output              cmos_rst_n  ,   //CMOS 复位信号
    output              cmos_pwdn   ,   //CMOS 休眠模式
    input               cmos_pclk   ,   //CMOS 数据时钟
    input               cmos_href   ,   //CMOS 行同步
    input               cmos_vsync  ,   //CMOS 场同步
    input   [ 7:0]      cmos_data   ,   //CMOS 像素数据
    output              cmos_scl    ,   //CMOS SCCB_SCL
    inout               cmos_sda    ,   //CMOS SCCB_SDA
    //SDRAM 
    output              sdram_clk   ,   //SDRAM 时钟
    output              sdram_cke   ,   //SDRAM 时钟有效
    output              sdram_cs_n  ,   //SDRAM 片选
    output              sdram_ras_n ,   //SDRAM 行有效
    output              sdram_cas_n ,   //SDRAM 列有效
    output              sdram_we_n  ,   //SDRAM 写有效
    output  [ 1:0]      sdram_ba    ,   //SDRAM Bank地址
    output  [ 1:0]      sdram_dqm   ,   //SDRAM 数据掩码
    output  [12:0]      sdram_addr  ,   //SDRAM 地址
    inout   [15:0]      sdram_dq    ,   //SDRAM 数据
    //TFT 
    output              TFT_clk     ,   //TFT 像素时钟
    output              TFT_rst     ,   //TFT 复位信号
    output              TFT_blank   ,   //TFT 背光控制
    output              TFT_hsync   ,   //TFT 行同步
    output              TFT_vsync   ,   //TFT 场同步
    output  [15:0]      TFT_data    ,   //TFT 像素输出
    output              TFT_de      ,   //TFT 数据使能
    //Segment 
    output              SH_CP       ,   //数码管 存储寄存器时钟
    output              ST_CP       ,   //数码管 移位寄存器时钟
    output              DS              //数码管 串行数据
);

    wire            rst_n           ;   //稳定后的复位信号
    //PLL 
    wire            clk_24m         ;   //24Mhz时钟
    wire            clk_100m        ;   //100Mhz时钟
    wire            clk_100m_shift  ;   //100Mhz时钟
    wire            clk_10m         ;   //10Mhz时钟
    wire            locked          ;   //PLL稳定信号
    //SDRAM 
    wire            wr_en           ;   //SDRAM写使能
    wire    [15:0]  wr_data         ;   //SDRAM写数据
    wire            rd_en           ;   //SDRAM读使能
    wire    [15:0]  rd_data         ;   //SDRAM读数据
    wire            sdram_init_done ;   //SDRAM初始化完成
    //RGB 
    wire            RGB_hsync       ;   //RGB行同步
    wire            RGB_vsync       ;   //RGB场同步
    wire    [15:0]  RGB_data        ;   //RGB数据
    wire            RGB_de          ;   //RGB数据使能
    //key 
    wire    [ 1:0]  key_vld         ;   //消抖后的按键值

//PLL
pll_clk u_pll_clk
(
    .inclk0             (sys_clk            ),  //输入系统时钟50Mhz
    .areset             (~sys_rst_n         ),  //输入复位信号

    .c0                 (clk_24m            ),  //输出时钟24Mhz
    .c1                 (clk_100m           ),  //输出时钟100mhz
    .c2                 (clk_100m_shift     ),  //输出时钟100Mhz,-75°偏移
    .c3                 (clk_10m            ),  //输出时钟10Mhz
    .locked             (locked             )   //输出时钟稳定指示
);

//复位信号 = 系统复位 + PLL稳定 + SDRAM初始化完成
assign rst_n = sys_rst_n & locked & sdram_init_done;

//ov5640

ov5640_top
#(
    .H_DISP             (H_DISP             ),  //图像宽度
    .V_DISP             (V_DISP             )   //图像高度
)       
u_ov5640_top        
(       
    .clk_24m            (clk_24m            ),  //时钟
    .rst_n              (rst_n              ),  //复位
    //cmos      
    .cmos_xclk          (cmos_xclk          ),  //CMOS 驱动时钟
    .cmos_rst_n         (cmos_rst_n         ),  //CMOS 复位信号
    .cmos_pwdn          (cmos_pwdn          ),  //CMOS 休眠模式
    .cmos_pclk          (cmos_pclk          ),  //CMOS 数据时钟
    .cmos_href          (cmos_href          ),  //CMOS 行同步信号
    .cmos_vsync         (cmos_vsync         ),  //CMOS 场同步信号
    .cmos_data          (cmos_data          ),  //CMOS 像素数据
    .cmos_scl           (cmos_scl           ),  //CMOS SCCB_SCL
    .cmos_sda           (cmos_sda           ),  //CMOS SCCB_SDA
    //RGB       
    .RGB_vld            (wr_en              ),  //RGB数据使能
    .RGB_data           (wr_data            ),  //RGB数据
    .FPS_rate           (FPS_rate           )   //FPS帧率
);

//SDRAM
sdram_top u_sdram_top
(
    .ref_clk            (clk_100m           ),  //SDRAM 控制器参考时钟
    .out_clk            (clk_100m_shift     ),  //给SDRAM器件的偏移时钟
    .rst_n              (sys_rst_n          ),  //系统复位
    //用户写端口 
    .wr_clk             (cmos_pclk          ),  //写端口FIFO: 写时钟
    .wr_en              (wr_en              ),  //写端口FIFO: 写使能
    .wr_data            (wr_data            ),  //写端口FIFO: 写数据
    .wr_min_addr        (24'd0              ),  //写SDRAM的起始地址
    .wr_max_addr        (H_DISP * V_DISP    ),  //写SDRAM的结束地址
    .wr_len             (10'd512            ),  //写SDRAM时的数据突发长度
    .wr_load            (~sys_rst_n         ),  //写端口复位: 复位写地址,清空写FIFO
    //用户读端口 
    .rd_clk             (clk_10m            ),  //读端口FIFO: 读时钟
    .rd_en              (rd_en              ),  //读端口FIFO: 读使能
    .rd_data            (rd_data            ),  //读端口FIFO: 读数据
    .rd_min_addr        (24'd0              ),  //读SDRAM的起始地址
    .rd_max_addr        (H_DISP * V_DISP    ),  //读SDRAM的结束地址
    .rd_len             (10'd512            ),  //从SDRAM中读数据时的突发长度
    .rd_load            (~sys_rst_n         ),  //读端口复位: 复位读地址,清空读FIFO
    //用户控制端口 
    .sdram_init_done    (sdram_init_done    ),  //SDRAM 初始化完成标志
    .sdram_pingpang_en  (1'b1               ),  //SDRAM 乒乓操作使能，图片0视频1
    //SDRAM 芯片接口 
    .sdram_clk          (sdram_clk          ),  //SDRAM 芯片时钟
    .sdram_cke          (sdram_cke          ),  //SDRAM 时钟有效
    .sdram_cs_n         (sdram_cs_n         ),  //SDRAM 片选
    .sdram_ras_n        (sdram_ras_n        ),  //SDRAM 行有效
    .sdram_cas_n        (sdram_cas_n        ),  //SDRAM 列有效
    .sdram_we_n         (sdram_we_n         ),  //SDRAM 写有效
    .sdram_ba           (sdram_ba           ),  //SDRAM Bank地址
    .sdram_addr         (sdram_addr         ),  //SDRAM 行/列地址
    .sdram_dq           (sdram_dq           ),  //SDRAM 数据
    .sdram_dqm          (sdram_dqm          )   //SDRAM 数据掩码
);

//TFT
TFT_driver u_TFT_driver 
(
    .clk                (clk_10m            ),  //时钟
    .rst_n              (rst_n              ),  //复位
    
    .TFT_req            (rd_en              ),  //输出数据请求
    .TFT_din            (rd_data            ),  //得到图像数据
    
    .TFT_clk            (TFT_clk            ),  //TFT数据时钟
    .TFT_rst            (TFT_rst            ),  //TFT复位信号
    .TFT_blank          (TFT_blank          ),  //TFT背光控制
    .TFT_hsync          (RGB_hsync          ),  //TFT行同步
    .TFT_vsync          (RGB_vsync          ),  //TFT场同步
    .TFT_data           (RGB_data           ),  //TFT数据输出
    .TFT_de             (RGB_de             )   //TFT数据使能   
);

//按键消抖
key_filter
#(
    .TIME_20MS          (200_000            ),  //20ms时间
    .KEY_W              (2                  )   //按键个数
)
u_key_filter
(
    .clk                (clk_10m            ),  //时钟
    .rst_n              (rst_n              ),  //复位
    .key                (key                ),  //按键输入
    
    .key_vld            (key_vld            )   //消抖后的按键值
);

//图像处理模块
ISP_top
#(
    .H_DISP             (H_DISP             ),  //图像宽度
    .V_DISP             (V_DISP             )   //图像高度
)
u_ISP_top
(
    .clk                (clk_10m            ),  //时钟
    .rst_n              (rst_n              ),  //复位
    //RGB 
    .RGB_hsync          (RGB_hsync          ),  //RGB行同步
    .RGB_vsync          (RGB_vsync          ),  //RGB场同步
    .RGB_data           (RGB_data           ),  //RGB数据
    .RGB_de             (RGB_de             ),  //RGB数据使能
    //key_vld 
    .key_vld            (key_vld            ),  //消抖后的按键值
    //DISP 
    .DISP_hsync         (TFT_hsync          ),  //最终显示的行同步
    .DISP_vsync         (TFT_vsync          ),  //最终显示的场同步
    .DISP_data          (TFT_data           ),  //最终显示的数据
    .DISP_de            (TFT_de             )   //最终显示的数据使能
);

endmodule 