//按键消抖，输出为1个clk的输入

module key_filter
#(
    parameter   TIME_20MS       = 1000000           , //20ms时间
    parameter   KEY_W           = 4                   //按键个数
)
(
    input                       clk                 , //时钟，50Mhz
    input                       rst_n               , //复位，低电平有效
    input        [KEY_W-1:0]    key                 , //按键输入
    output  reg  [KEY_W-1:0]    key_vld               //按键消抖后的输出
);

reg   [20:0]        cnt     ;
wire                add_cnt ;
wire                end_cnt ;
reg   [KEY_W -1:0]  key_r0  ;
reg   [KEY_W -1:0]  key_r1  ;
reg                 flag    ;

//信号同步、消除亚稳态
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key_r0 <= 'd0;
        key_r1 <= 'd0;
    end
    else begin
        key_r0 <= ~key;     //按键高电平有效则需去掉~
        key_r1 <= key_r0;   //打拍，防亚稳态
    end
end

//20ms计时
//计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cnt <= 'd0;
    else if(add_cnt)begin
        if(end_cnt)
            cnt <= 'd0;
        else
            cnt <= cnt + 1'b1;
    end
end

assign add_cnt = flag==0 && key_r1!=0 ;        //允许计数 且 按键按下
assign end_cnt = add_cnt && cnt==TIME_20MS-1;  //计到20ms

//计满指示
always @(posedge clk or negedge rst_n)begin
    if(!rst_n) begin                 //复位
        flag <= 'd0;                 //flag=0允许计数
    end
    else if(end_cnt) begin           //20ms到
        flag <= 'd1;                 //flag=1不再计数
    end
    else if(key_r1==0) begin         //按键松开
        flag <= 'd0;                 //flag=0，为下次计数做准备
    end
end

//==    按键消抖完成，输出按键有效信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key_vld <= 'd0;
    end
    else if(end_cnt) begin       //20ms到
        key_vld <= key_r1;       //按键已消抖，可以使用
    end
    else begin
        key_vld <= 'd0;
    end
end

endmodule