//3x3矩阵，边界采用像素复制，最大支持1024x1024，耗费1clk

module matrix_3x3_8bit
#(
    parameter H_DISP            = 12'd480               ,   //图像宽度
    parameter V_DISP            = 12'd272                   //图像高度
)
(
    input   wire                clk                     ,
    input   wire                rst_n                   ,
    input   wire                din_vld                 ,
    input   wire    [ 7:0]      din                     ,

    output  reg     [ 7:0]      matrix_11               ,
    output  reg     [ 7:0]      matrix_12               ,
    output  reg     [ 7:0]      matrix_13               ,
    output  reg     [ 7:0]      matrix_21               ,
    output  reg     [ 7:0]      matrix_22               ,
    output  reg     [ 7:0]      matrix_23               ,
    output  reg     [ 7:0]      matrix_31               ,
    output  reg     [ 7:0]      matrix_32               ,
    output  reg     [ 7:0]      matrix_33                
);

reg     [11:0]  cnt_col     ;
wire            add_cnt_col ;
wire            end_cnt_col ;
reg     [11:0]  cnt_row     ;
wire            add_cnt_row ;
wire            end_cnt_row ;
wire            wr_en_1     ;
wire            wr_en_2     ;
wire            rd_en_1     ;
wire            rd_en_2     ;
wire    [ 7:0]  q_1         ;
wire    [ 7:0]  q_2         ;
wire    [ 7:0]  row_1       ;
wire    [ 7:0]  row_2       ;
wire    [ 7:0]  row_3       ;

//FIFO例化，show模式，深度为大于两行数据个数
fifo_show_2048x8 u1
(
    .clock      (clk        ),
    .data       (din        ),
    .wrreq      (wr_en_1    ),
    .rdreq      (rd_en_1    ),
    .q          (q_1        )
);

fifo_show_2048x8 u2
(
    .clock      (clk        ),
    .data       (din        ),
    .wrreq      (wr_en_2    ),
    .rdreq      (rd_en_2    ),
    .q          (q_2        )
);

//行列划分
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_col <= 12'd0;
    else if(add_cnt_col) begin
        if(end_cnt_col)
            cnt_col <= 12'd0;
        else
            cnt_col <= cnt_col + 12'd1;
    end
end

assign add_cnt_col = din_vld;
assign end_cnt_col = add_cnt_col && cnt_col== H_DISP-12'd1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt_row <= 12'd0;
    else if(add_cnt_row) begin
        if(end_cnt_row)
            cnt_row <= 12'd0;
        else
            cnt_row <= cnt_row + 12'd1;
    end
end

assign add_cnt_row = end_cnt_col;
assign end_cnt_row = add_cnt_row && cnt_row== V_DISP-12'd1;

//fifo 读写信号
assign wr_en_1 = (cnt_row < V_DISP - 12'd1) ? din_vld : 1'd0; //不写最后1行
assign rd_en_1 = (cnt_row > 12'd0         ) ? din_vld : 1'd0; //从第1行开始读
assign wr_en_2 = (cnt_row < V_DISP - 12'd2) ? din_vld : 1'd0; //不写最后2行
assign rd_en_2 = (cnt_row > 12'd1         ) ? din_vld : 1'd0; //从第2行开始读

//形成 3x3 矩阵，边界采用像素复制

//矩阵数据选取
assign row_1 = q_2;
assign row_2 = q_1;
assign row_3 = din;

//打拍形成矩阵，1clk
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        {matrix_11, matrix_12, matrix_13} <= {8'd0, 8'd0, 8'd0};
        {matrix_21, matrix_22, matrix_23} <= {8'd0, 8'd0, 8'd0};
        {matrix_31, matrix_32, matrix_33} <= {8'd0, 8'd0, 8'd0};
    end
    //第1排矩阵
    else if(cnt_row == 12'd0) begin
        if(cnt_col == 12'd0) begin          //第1个矩阵
            {matrix_11, matrix_12, matrix_13} <= {row_3, row_3, row_3};
            {matrix_21, matrix_22, matrix_23} <= {row_3, row_3, row_3};
            {matrix_31, matrix_32, matrix_33} <= {row_3, row_3, row_3};
        end
        else begin                          //剩余矩阵
            {matrix_11, matrix_12, matrix_13} <= {matrix_12, matrix_13, row_3};
            {matrix_21, matrix_22, matrix_23} <= {matrix_22, matrix_23, row_3};
            {matrix_31, matrix_32, matrix_33} <= {matrix_32, matrix_33, row_3};
        end
    end
    //第2排矩阵
    else if(cnt_row == 12'd1) begin
        if(cnt_col == 12'd0) begin          //第1个矩阵
            {matrix_11, matrix_12, matrix_13} <= {row_2, row_2, row_2};
            {matrix_21, matrix_22, matrix_23} <= {row_2, row_2, row_2};
            {matrix_31, matrix_32, matrix_33} <= {row_3, row_3, row_3};
        end
        else begin                          //剩余矩阵
            {matrix_11, matrix_12, matrix_13} <= {matrix_12, matrix_13, row_2};
            {matrix_21, matrix_22, matrix_23} <= {matrix_22, matrix_23, row_2};
            {matrix_31, matrix_32, matrix_33} <= {matrix_32, matrix_33, row_3};
        end
    end
    //剩余矩阵
    else begin
        if(cnt_col == 12'd0) begin          //第1个矩阵
            {matrix_11, matrix_12, matrix_13} <= {row_1, row_1, row_1};
            {matrix_21, matrix_22, matrix_23} <= {row_2, row_2, row_2};
            {matrix_31, matrix_32, matrix_33} <= {row_3, row_3, row_3};
        end
        else begin                          //剩余矩阵
            {matrix_11, matrix_12, matrix_13} <= {matrix_12, matrix_13, row_1};
            {matrix_21, matrix_22, matrix_23} <= {matrix_22, matrix_23, row_2};
            {matrix_31, matrix_32, matrix_33} <= {matrix_32, matrix_33, row_3};
        end
    end
end

endmodule