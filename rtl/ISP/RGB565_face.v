//RGB565转YCbCr444，再根据肤色范围进行二值化
//        Y   =   0.299*R + 0.587*G + 0.114*B
//        Cb  =   0.586*(B-Y) + 128 = -0.172*R - 0.339*G + 0.511*B + 128
//        Cr  =   0.713*(R-Y) + 128 =  0.511*R - 0.428*G - 0.083*B + 128
// --->
//        Y   =   ( 77*R  +  150*G  +   29*B) >> 8
//        Cb  =   (-43*R  -   85*G  +  128*B) >> 8 + 128
//        Cr  =   (128*R  -  107*G  -   21*B) >> 8 + 128
// --->
//        Y   =   ( 77*R  +  150*G  +   29*B) >> 8
//        Cb  =   (-43*R  -   85*G  +  128*B + 32768) >> 8
//        Cr  =   (128*R  -  107*G  -   21*B + 32768) >> 8

module RGB565_face
#(
    parameter H_DISP     = 12'd480  ,   //图像宽度
    parameter V_DISP     = 12'd272      //图像高度
)
(
    input   wire            clk         ,   //时钟
    input   wire            rst_n       ,   //复位
    //input 
    input   wire            RGB_hsync   ,     //RGB行同步
    input   wire            RGB_vsync   ,     //RGB场同步
    input   wire    [15:0]  RGB_data    ,     //RGB数据
    input   wire            RGB_de      ,     //RGB数据使能
    //output    
    output  wire            face_hsync  ,     //face行同步
    output  wire            face_vsync  ,     //face场同步
    output  wire    [ 7:0]  face_data   ,     //face数据（二值化数据）
    output  wire            face_de           //face数据使能
);

wire    [ 7:0]  R0, G0, B0      ;
reg     [15:0]  R1, G1, B1      ;
reg     [15:0]  R2, G2, B2      ;
reg     [15:0]  R3, G3, B3      ;
reg     [15:0]  Y1, Cb1, Cr1    ;
reg     [ 7:0]  Y2, Cb2, Cr2    ;
reg     [ 3:0]  RGB_de_r        ;
reg     [ 3:0]  RGB_hsync_r     ;
reg     [ 3:0]  RGB_vsync_r     ;

//RGB565转RGB888
assign R0 = {RGB_data[15:11],RGB_data[13:11]};
assign G0 = {RGB_data[10: 5],RGB_data[ 6: 5]};
assign B0 = {RGB_data[ 4: 0],RGB_data[ 2: 0]};

//RGB888转YCbCr
//clk 1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        {R1,G1,B1} <= {16'd0, 16'd0, 16'd0};
        {R2,G2,B2} <= {16'd0, 16'd0, 16'd0};
        {R3,G3,B3} <= {16'd0, 16'd0, 16'd0};
    end
    else begin
        {R1,G1,B1} <= { {R0 * 16'd77},  {G0 * 16'd150}, {B0 * 16'd29 } };
        {R2,G2,B2} <= { {R0 * 16'd43},  {G0 * 16'd85},  {B0 * 16'd128} };
        {R3,G3,B3} <= { {R0 * 16'd128}, {G0 * 16'd107}, {B0 * 16'd21 } };
    end
end

//clk 2
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        Y1  <= 16'd0;
        Cb1 <= 16'd0;
        Cr1 <= 16'd0;
    end
    else begin
        Y1  <= R1 + G1 + B1;
        Cb1 <= B2 - R2 - G2 + 16'd32768; //32768=128*256
        Cr1 <= R3 - G3 - B3 + 16'd32768; 
    end
end

//clk 3，除以256即右移8位，即取高8位
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        Y2  <= 8'd0;
        Cb2 <= 8'd0;
        Cr2 <= 8'd0;
    end
    else begin
        Y2  <= Y1[15:8];  
        Cb2 <= Cb1[15:8];
        Cr2 <= Cr1[15:8];
    end
end

//clk 根据目标物体颜色范围进行二值化
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        bina_data <= 8'h0;
    end
    else if( (Cb2 > 8'd90) && (Cb2 < 8'd120) && (Cr2 > 8'd140) && (Cr2 < 8'd170) ) begin //肤色
//    else if( (Cb2 > 8'd16) && (Cb2 < 8'd46) && (Cr2 > 8'd140) && (Cr2 < 8'd170) ) begin //黄色
//      else if( (Cr2 > 8'd175) && (Cr2 < 8'd255) ) begin //红色
        bina_data <= 8'hff;
    end
    else begin
        bina_data <= 8'h0;
    end
end

//信号同步
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        RGB_de_r    <= 4'b0;
        RGB_hsync_r <= 4'b0;
        RGB_vsync_r <= 4'b0;
    end
    else begin  
        RGB_de_r    <= {RGB_de_r[2:0],    RGB_de};
        RGB_hsync_r <= {RGB_hsync_r[2:0], RGB_hsync};
        RGB_vsync_r <= {RGB_vsync_r[2:0], RGB_vsync};
    end
end



assign bina_de    = RGB_de_r[3];
assign bina_hsync = RGB_hsync_r[3];
assign bina_vsync = RGB_vsync_r[3];


wire            bina_de   ;
wire            bina_hsync;
wire            bina_vsync;
reg     [7:0]   bina_data ;

wire            erode_de   ;
wire            erode_hsync;
wire            erode_vsync;
wire    [7:0]   erode_data ;

erode
#(
    .H_DISP         (H_DISP     ),   //图像宽度
    .V_DISP         (V_DISP     )    //图像高度
)
u_erode
(
    .clk            (clk            ),
    .rst_n          (rst_n          ),
    .bina_de        (bina_de        ),   //bina分量数据使能
    .bina_hsync     (bina_hsync     ),   //bina分量行同步
    .bina_vsync     (bina_vsync     ),   //bina分量场同步
    .bina_data      (bina_data      ),   //bina分量数据

    .erode_de       (erode_de       ),   //erode数据使能
    .erode_hsync    (erode_hsync    ),   //erode行同步
    .erode_vsync    (erode_vsync    ),   //erode场同步
    .erode_data     (erode_data     )    //erode数据
);


dilate
#(
    .H_DISP         (H_DISP         ),   //图像宽度
    .V_DISP         (V_DISP         )    //图像高度
)
u_dilate
(
    .clk            (clk            ), 
    .rst_n          (rst_n          ), 
    .bina_de        (erode_de       ),   //bina分量数据使能
    .bina_hsync     (erode_hsync    ),   //bina分量行同步
    .bina_vsync     (erode_vsync    ),   //bina分量场同步
    .bina_data      (erode_data     ),   //bina分量数据

    .dilate_de      (face_de        ),   //dilate数据使能
    .dilate_hsync   (face_hsync     ),   //dilate行同步
    .dilate_vsync   (face_vsync     ),   //dilate场同步
    .dilate_data    (face_data      )    //dilate数据
);

endmodule