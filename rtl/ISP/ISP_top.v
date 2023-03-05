module ISP_top
#(
    parameter H_DISP        = 12'd480   ,   //图像宽度
    parameter V_DISP        = 12'd272       //图像高度
)
(
    input   wire            clk         ,   //时钟
    input   wire            rst_n       ,   //复位
    //RGB 
    input   wire            RGB_hsync   ,   //RGB行同步
    input   wire            RGB_vsync   ,   //RGB场同步
    input   wire    [15:0]  RGB_data    ,   //RGB数据
    input   wire            RGB_de      ,   //RGB数据使能
    //key 
    input   wire    [ 1:0]  key_vld     ,   //消抖后的按键值
    //DISP 
    output  wire            DISP_hsync  ,   //最终显示的行同步
    output  wire            DISP_vsync  ,   //最终显示的场同步
    output  wire    [15:0]  DISP_data   ,   //最终显示的数据
    output  wire            DISP_de         //最终显示的数据使能
);

//face 
wire            face_hsync  ;   //face行同步
wire            face_vsync  ;   //face场同步
wire    [ 7:0]  face_data   ;   //face数据
wire            face_de     ;   //face数据使能

//RGB565转YCbCr444，再根据肤色范围进行二值化
RGB565_face u_RGB565_face
(
    .clk        (clk        ),  //时钟
    .rst_n      (rst_n      ),  //复位
    //RGB  
    .RGB_hsync  (RGB_hsync  ),  //RGB行同步
    .RGB_vsync  (RGB_vsync  ),  //RGB场同步
    .RGB_data   (RGB_data   ),  //RGB数据
    .RGB_de     (RGB_de     ),  //RGB数据使能
    //face  
    .face_hsync (face_hsync ),  //face行同步
    .face_vsync (face_vsync ),  //face场同步
    .face_data  (face_data  ),  //face数据
    .face_de    (face_de    )   //face数据使能
);

//添加包围盒后输出
img_box
#(
    .H_DISP     (H_DISP     ),  //图像宽度
    .V_DISP     (V_DISP     )   //图像高度
)
u_img_box
(
    .clk        (clk        ),  //时钟
    .rst_n      (rst_n      ),  //复位
    //RGB  
    .RGB_hsync  (RGB_hsync  ),  //RGB行同步
    .RGB_vsync  (RGB_vsync  ),  //RGB场同步
    .RGB_data   (RGB_data   ),  //RGB数据
    .RGB_de     (RGB_de     ),  //RGB数据使能
    //face 
    .face_hsync (face_hsync ),  //face行同步
    .face_vsync (face_vsync ),  //face场同步
    .face_data  (face_data  ),  //face数据
    .face_de    (face_de    ),  //face数据使能
    //key 
    .key_vld    (key_vld    ),  //消抖后的按键值
    //DISP 
    .DISP_hsync (DISP_hsync ),  //最终显示的行同步
    .DISP_data  (DISP_data  ),  //最终显示的数据
    .DISP_de    (DISP_de    ),  //最终显示的数据使能 
    .DISP_vsync (DISP_vsync )   //最终显示的场同步
);

endmodule