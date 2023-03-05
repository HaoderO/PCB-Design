//膨胀处理，输入为二值图像

module dilate
#(
    parameter   H_DISP      = 12'd480       ,   //图像宽度
    parameter   V_DISP      = 12'd272           //图像高度
)
(
    input   wire            clk             ,   //时钟
    input   wire            rst_n           ,   //复位
    input   wire            bina_de         ,   //bina分量行同步
    input   wire            bina_hsync      ,   //bina分量场同步
    input   wire            bina_vsync      ,   //bina分量数据
    input   wire    [ 7:0]  bina_data       ,   //bina分量数据使能

    output  wire            dilate_de       ,   //dilate行同步
    output  wire            dilate_hsync    ,   //dilate场同步
    output  wire            dilate_vsync    ,   //dilate数据
    output  wire    [ 7:0]  dilate_data         //dilate数据使能
);

//matrix_3x3
wire    [ 7:0]  matrix_11   ;
wire    [ 7:0]  matrix_12   ;
wire    [ 7:0]  matrix_13   ;
wire    [ 7:0]  matrix_21   ;
wire    [ 7:0]  matrix_22   ;
wire    [ 7:0]  matrix_23   ;
wire    [ 7:0]  matrix_31   ;
wire    [ 7:0]  matrix_32   ;
wire    [ 7:0]  matrix_33   ;

//dilate 
reg     dilate_1    ;
reg     dilate_2    ;
reg     dilate_3    ;
reg     dilate      ;

//同步 
reg     [ 2:0]  bina_de_r       ;
reg     [ 2:0]  bina_hsync_r    ;
reg     [ 2:0]  bina_vsync_r    ;

//matrix_3x3_8bit，生成3x3矩阵，输入和使能需对齐，耗费1clk
matrix_3x3_8bit
#(
    .H_DISP                 (H_DISP     ),
    .V_DISP                 (V_DISP     ) 
)
u_matrix_3x3_8bit
(
    .clk                    (clk        ),
    .rst_n                  (rst_n      ),
    .din_vld                (bina_de    ),
    .din                    (bina_data  ),
    .matrix_11              (matrix_11  ),
    .matrix_12              (matrix_12  ),
    .matrix_13              (matrix_13  ),
    .matrix_21              (matrix_21  ),
    .matrix_22              (matrix_22  ),
    .matrix_23              (matrix_23  ),
    .matrix_31              (matrix_31  ),
    .matrix_32              (matrix_32  ),
    .matrix_33              (matrix_33  )
);

//膨胀，耗费2clk
//clk1，三行各自相或
always @ (posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        dilate_1 <= 'd0;
        dilate_2 <= 'd0;
        dilate_3 <= 'd0;
    end
    else begin
        dilate_1 <= matrix_11 || matrix_12 || matrix_13;
        dilate_2 <= matrix_21 || matrix_22 || matrix_23;
        dilate_3 <= matrix_31 || matrix_32 || matrix_33;
    end
end

//clk2，全部相或
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        dilate <= 'd0;
    end
    else begin
        dilate <= dilate_1 || dilate_2 || dilate_3;
    end
end

//膨胀后的数据
assign dilate_data = dilate ? 8'hff : 8'h00;

//信号同步
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        bina_de_r    <= 3'b0;
        bina_hsync_r <= 3'b0;
        bina_vsync_r <= 3'b0;
    end
    else begin  
        bina_de_r    <= {bina_de_r[1:0],    bina_de};
        bina_hsync_r <= {bina_hsync_r[1:0], bina_hsync};
        bina_vsync_r <= {bina_vsync_r[1:0], bina_vsync};
    end
end

assign dilate_de    = bina_de_r[2];
assign dilate_hsync = bina_hsync_r[2];
assign dilate_vsync = bina_vsync_r[2];
    
endmodule