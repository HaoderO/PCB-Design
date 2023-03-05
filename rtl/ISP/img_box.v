module img_box
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
    //face 
    input   wire            face_hsync  ,   //face行同步
    input   wire            face_vsync  ,   //face场同步
    input   wire    [ 7:0]  face_data   ,   //face数据
    input   wire            face_de     ,   //face数据使能
    //key 
    input   wire    [ 1:0]  key_vld     ,   //消抖后的按键值
    //DISP 
    output  reg             DISP_hsync  ,   //最终显示的行同步
    output  reg             DISP_vsync  ,   //最终显示的场同步
    output  reg     [15:0]  DISP_data   ,   //最终显示的数据 
    output  reg             DISP_de         //最终显示的数据使能          
);

reg             face_vsync_r ;
wire            pos_vsync    ;
wire            neg_vsync    ;

reg     [11:0]  face_x       ;
wire            add_face_x   ;
wire            end_face_x   ;
reg     [11:0]  face_y       ;
wire            add_face_y   ;
wire            end_face_y   ;

reg     [11:0]  x_min        ;
reg     [11:0]  x_max        ;
reg     [11:0]  y_min        ;
reg     [11:0]  y_max        ;
reg     [11:0]  x_min_r      ;
reg     [11:0]  x_max_r      ;
reg     [11:0]  y_min_r      ;
reg     [11:0]  y_max_r      ;

reg     [11:0]  RGB_x        ;
wire            add_RGB_x    ;
wire            end_RGB_x    ;
reg     [11:0]  RGB_y        ;
wire            add_RGB_y    ;
wire            end_RGB_y    ;

reg             mode         ;

//帧开始和结束标志
always @(posedge clk) begin
    face_vsync_r <= face_vsync;
end

assign pos_vsync =  face_vsync && ~face_vsync_r;
assign neg_vsync = ~face_vsync &&  face_vsync_r;

//肤色图像的行列划分
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        face_x <= 12'd0;
    else if(add_face_x) begin
        if(end_face_x)
            face_x <= 12'd0;
        else
            face_x <= face_x + 12'd1;
    end
end

assign add_face_x = face_de;
assign end_face_x = add_face_x && face_x== H_DISP-12'd1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        face_y <= 12'd0;
    else if(add_face_y) begin
        if(end_face_y)
            face_y <= 12'd0;
        else
            face_y <= face_y + 12'd1;
    end
end

assign add_face_y = end_face_x;
assign end_face_y = add_face_y && face_y== V_DISP-12'd1;

//帧运行：人脸框选
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_min <= H_DISP;
    end
    else if(pos_vsync) begin
        x_min <= H_DISP;
    end
    else if(face_data==8'hff && x_min > face_x && face_de) begin
        x_min <= face_x;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_max <= 'd0;
    end
    else if(pos_vsync) begin
        x_max <= 'd0;
    end
    else if(face_data==8'hff && x_max < face_x && face_de) begin
        x_max <= face_x;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        y_min <= V_DISP;
    end
    else if(pos_vsync) begin
        y_min <= V_DISP;
    end
    else if(face_data==8'hff && y_min > face_y && face_de) begin
        y_min <= face_y;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        y_max <= 'd0;
    end
    else if(pos_vsync) begin
        y_max <= 'd0;
    end
    else if(face_data==8'hff && y_max < face_y && face_de) begin
        y_max <= face_y;
    end
end

//帧结束：保存坐标值
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_min_r <= 'd0;
        x_max_r <= 'd0;
        y_min_r <= 'd0;
        y_max_r <= 'd0;
    end
    else if(neg_vsync) begin
        x_min_r <= x_min;
        x_max_r <= x_max;
        y_min_r <= y_min;
        y_max_r <= y_max;
    end
end

//原图的行列划分
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        RGB_x <= 12'd0;
    else if(add_RGB_x) begin
        if(end_RGB_x)
            RGB_x <= 12'd0;
        else
            RGB_x <= RGB_x + 12'd1;
    end
end

assign add_RGB_x = RGB_de;
assign end_RGB_x = add_RGB_x && RGB_x== H_DISP-12'd1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        RGB_y <= 12'd0;
    else if(add_RGB_y) begin
        if(end_RGB_y)
            RGB_y <= 12'd0;
        else
            RGB_y <= RGB_y + 12'd1;
    end
end

assign add_RGB_y = end_RGB_x;
assign end_RGB_y = add_RGB_y && RGB_y== V_DISP-12'd1;

//按键切换不同显示效果
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mode <= 1'b0;
    end
    else if(key_vld[0]) begin
        mode <= 1'b1;
    end
    else if(key_vld[1]) begin
        mode <= 1'b0;
    end
end

//输出图像
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        DISP_hsync <= 1'b0;
        DISP_vsync <= 1'b0;
        DISP_data  <= 16'b0;
        DISP_de    <= 1'b0;
    end
    //输出目标框和原图
    else if(mode==1'b0) begin
        DISP_hsync <= RGB_hsync;
        DISP_vsync <= RGB_vsync;
        DISP_de    <= RGB_de;
        
        if((RGB_y >= y_min_r-1 && RGB_y <= y_min_r+1) && RGB_x >= x_min_r && RGB_x <= x_max_r) begin
            DISP_data <= 16'h07e0;
        end
        else if((RGB_y >= y_max_r-1 && RGB_y <= y_max_r+1) && RGB_x >= x_min_r && RGB_x <= x_max_r) begin
            DISP_data <= 16'h07e0;
        end
        else if((RGB_x >= x_min_r-1 && RGB_x <= x_min_r+1) && RGB_y >= y_min_r && RGB_y <= y_max_r) begin
            DISP_data <= 16'h07e0;
        end
        else if((RGB_x >= x_max_r-1 && RGB_x <= x_max_r+1) && RGB_y >= y_min_r && RGB_y <= y_max_r) begin
            DISP_data <= 16'h07e0;
        end
        else begin
            DISP_data  <= RGB_data;
        end
    end
    //输出目标框和二值化的肤色图
    else if(mode==1'b1) begin
        DISP_vsync <= face_vsync;
        DISP_de    <= face_de;
        DISP_hsync <= face_hsync;
        
        if((face_y >= y_min_r-1 && face_y <= y_min_r+1) && face_x >= x_min_r && face_x <= x_max_r) begin
            DISP_data <= 16'h07e0;
        end
        else if((face_y >= y_max_r-1 && face_y <= y_max_r+1) && face_x >= x_min_r && face_x <= x_max_r) begin
            DISP_data <= 16'h07e0;
        end
        else if((face_x >= x_min_r-1 && face_x <= x_min_r+1) && face_y >= y_min_r && face_y <= y_max_r) begin
            DISP_data <= 16'h07e0;
        end
        else if((face_x >= x_max_r-1 && face_x <= x_max_r+1) && face_y >= y_min_r && face_y <= y_max_r) begin
            DISP_data <= 16'h07e0;
        end
        else begin
            DISP_data  <= {face_data[7:3],face_data[7:2],face_data[7:3]};
        end
    end
end

endmodule