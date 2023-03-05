//摄像头原始数据转RGB565数据，裁剪后输出
module cmos_capture
#(
parameter CMOS_H_PIXEL      = 12'd640               ,   //CMOS输出宽度
parameter CMOS_V_PIXEL      = 12'd480               ,   //CMOS输出高度
parameter H_DISP            = 12'd480               ,   //图像宽度
parameter V_DISP            = 12'd272                   //图像高度
)
(
input   wire                clk_24m                 ,   //24Mhz
input   wire                cmos_pclk               ,   //cmos数据像素时钟
input   wire                rst_n                   ,   //复位，低电平有效
//cmos 
input   wire                cmos_href               ,   //CMOS 行同步
input   wire                cmos_vsync              ,   //CMOS 场同步
input   wire    [ 7:0]      cmos_data               ,   //CMOS 像素数据
//RGB 
output  wire                RGB_vld                 ,   //RGB数据使能
output  wire    [15:0]      RGB_data                ,   //RGB数据
output  reg     [ 7:0]      FPS_rate                    //帧率
);

parameter WAIT              = 10                             ;  //等待10帧
parameter TIME_1S           = 24_000000                      ;  //1s时间
        
parameter H_START           = CMOS_H_PIXEL[11:2]-H_DISP[11:2];  //裁剪后的宽度起始
parameter H_STOP            = H_START + H_DISP               ;  //裁剪后的宽度结束
parameter V_START           = CMOS_V_PIXEL[11:2]-V_DISP[11:2];  //裁剪后的高度起始
parameter V_STOP            = V_START + V_DISP               ;  //裁剪后的高度结束 

reg                         cmos_vsync_r1           ;
reg                         cmos_vsync_r2           ;
reg                         cmos_href_r1            ;
reg                         cmos_href_r2            ;
wire                        cmos_vsync_pos          ;
reg     [ 3:0]              frame_cnt               ;
wire                        frame_vld               ;
reg                         byte_flag               ;

reg     [11:0]              cnt_h                   ;
wire                        add_cnt_h               ;
wire                        end_cnt_h               ;
reg     [11:0]              cnt_v                   ;
wire                        add_cnt_v               ;
wire                        end_cnt_v               ;
reg                         RGB565_vld              ;
reg     [15:0]              RGB565_data             ;

wire                        frame_vsync             ;
wire                        frame_hsync             ;
reg                         frame_vsync_r           ;
wire                        frame_vsync_pos         ;
reg     [24:0]              cnt_1s                  ;
wire                        add_cnt_1s              ;
wire                        end_cnt_1s              ;
reg     [ 7:0]              cnt_FPS                 ;

//打拍，以供后面程序使用
always @(posedge cmos_pclk or negedge rst_n) begin
    if(!rst_n) begin
        cmos_vsync_r1 <= 1'b0;
        cmos_vsync_r2 <= 1'b0;
        cmos_href_r1  <= 1'b0;
        cmos_href_r2  <= 1'b0;
    end
    else begin
        cmos_vsync_r1 <= cmos_vsync;
        cmos_vsync_r2 <= cmos_vsync_r1;
        cmos_href_r1  <= cmos_href;
        cmos_href_r2  <= cmos_href_r1;
    end
end

//前10帧图像数据不稳定，丢弃掉
//vsync上升沿
assign cmos_vsync_pos = (~cmos_vsync_r1 & cmos_vsync);

//帧有效信号，去除前10帧
always @(posedge cmos_pclk or negedge rst_n) begin
    if(!rst_n) begin
        frame_cnt <= 'd0;
    end
    else if(cmos_vsync_pos && frame_vld==1'b0) begin
        frame_cnt <= frame_cnt + 1'b1;
    end
end

assign frame_vld = (frame_cnt >= WAIT) ? 1'b1 : 1'b0;

//两个原始数据拼成一个RGB565像素
//字节指示
always  @(posedge cmos_pclk or negedge rst_n) begin
    if(!rst_n) begin
        byte_flag <= 1'b0;
    end
    else if(cmos_href) begin
        byte_flag <= ~byte_flag;
    end
    else begin
        byte_flag <= 1'b0;
    end
end

//RGB_data
always  @(posedge cmos_pclk or negedge rst_n) begin
    if(!rst_n) begin
        RGB565_data <= 'h0;
    end
    else if(byte_flag == 1'b0) begin                    //first byte
        RGB565_data <= {cmos_data, RGB565_data[7:0]};
    end
    else if(byte_flag == 1'b1) begin                    //second byte
        RGB565_data <= {RGB565_data[15:8], cmos_data};
    end
end

//RGB_vld
always  @(posedge cmos_pclk or negedge rst_n) begin
    if(!rst_n) begin
        RGB565_vld <= 1'b0;
    end
    else if(frame_vld && byte_flag) begin
        RGB565_vld <= 1'b1;
    end
    else begin
        RGB565_vld <= 1'b0;
    end
end

//分辨率裁剪
//行计数
always @(posedge cmos_pclk or negedge rst_n) begin
    if(!rst_n)
        cnt_h <= 'd0;
    else if(add_cnt_h) begin
        if(end_cnt_h)
            cnt_h <= 'd0;
        else
            cnt_h <= cnt_h + 1'b1;
    end
end

assign add_cnt_h = RGB565_vld;
assign end_cnt_h = add_cnt_h && cnt_h== CMOS_H_PIXEL-1;

//场计数
always @(posedge cmos_pclk or negedge rst_n) begin 
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
assign end_cnt_v = add_cnt_v && cnt_v== CMOS_V_PIXEL-1;

//裁剪后的数据：适配显示屏
assign RGB_data = RGB565_data;
assign RGB_vld  = RGB565_vld && (cnt_h >= H_START) && (cnt_h < H_STOP)
                             && (cnt_v >= V_START) && (cnt_v < V_STOP);

//帧率计算，不能用pclk时钟，需重新捕捉vsync_pos
//输出行场有效信号
assign frame_vsync = frame_vld ? cmos_vsync_r2 : 1'b0;
assign frame_hsync = frame_vld ? cmos_href_r2  : 1'b0;

//vsync上升沿
always @(posedge clk_24m or negedge rst_n) begin
    if(!rst_n)
        frame_vsync_r <= 1'b0;
    else
        frame_vsync_r <= frame_vsync;
end

assign frame_vsync_pos = (~frame_vsync_r & frame_vsync);

//1s时间
always @(posedge clk_24m or negedge rst_n) begin
    if(!rst_n)
        cnt_1s <= 'd0;
    else if(add_cnt_1s) begin
        if(end_cnt_1s)
            cnt_1s <= 'd0;
        else
            cnt_1s <= cnt_1s + 1'b1;
    end
end

assign add_cnt_1s = frame_vld;
assign end_cnt_1s = add_cnt_1s && cnt_1s== TIME_1S-1;

//1s时间内的vsync次数
always @(posedge clk_24m or negedge rst_n) begin
    if(!rst_n)
        cnt_FPS <= 'd0;
    else if(end_cnt_1s) begin
        cnt_FPS <= 'd0;
    end
    else if(frame_vld && frame_vsync_pos)begin
        cnt_FPS <= cnt_FPS + 'd1;
    end
end

//实时更新帧率值
always @(posedge clk_24m or negedge rst_n) begin
    if(!rst_n) begin
        FPS_rate <= 'd0;
    end
    else if(end_cnt_1s) begin
        FPS_rate <= cnt_FPS;
    end
end

endmodule 