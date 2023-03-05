//SCCB控制器，只写

module sccb
#(
    parameter DEVICE_ID     = 8'h78             , //器件ID
    parameter CLK           = 26'd24_000_000    , //本模块的时钟频率
    parameter SCL           = 18'd250_000         //输出的SCL时钟频率
)
(
    input   wire            clk                 , //时钟
    input   wire            rst_n               , //复位，低电平有效
    //SCCB input  
    input   wire            sccb_en             , //SCCB触发信号
    input   wire    [15:0]  sccb_addr           , //SCCB器件内地址
    input   wire    [ 7:0]  sccb_data           , //SCCB要写的数据
    //SCCB output  
    output  reg             sccb_done           , //SCCB一次操作完成
    output  reg             sccb_scl            , //SCCB的SCL时钟信号
    inout   wire            sccb_sda            , //SCCB的SDA数据信号
    //dri_clk  
    output  reg             sccb_dri_clk          //驱动SCCB操作的驱动时钟，1Mhz
);

localparam  IDLE    = 6'b00_0001    ; //空闲状态
localparam  DEVICE  = 6'b00_0010    ; //写器件地址
localparam  ADDR_16 = 6'b00_0100    ; //写字地址高8位
localparam  ADDR_8  = 6'b00_1000    ; //写字地址低8位
localparam  DATA    = 6'b01_0000    ; //写数据
localparam  STOP    = 6'b10_0000    ; //结束

reg             sda_dir     ; //SCCB数据(SDA)方向控制
reg             sda_out     ; //SDA输出信号
reg             state_done  ; //状态结束
reg    [ 6:0]   cnt         ; //计数
reg    [ 7:0]   state_c     ; //状态机当前状态
reg    [ 7:0]   state_n     ; //状态机下一状态
reg    [15:0]   sccb_addr_t ; //地址寄存
reg    [ 7:0]   sccb_data_t ; //数据寄存
reg    [ 9:0]   clk_cnt     ; //分频时钟计数
wire   [ 8:0]   clk_divide  ; //模块驱动时钟的分频系数

//SDA数据输出或高阻
assign  sccb_sda = sda_dir ?  sda_out : 1'bz;         

//生成SCL的4倍时钟来驱动后面SCCB的操作，生成1Mhz的sccb_dri_clk
assign  clk_divide = (CLK/SCL) >> 3; //>>3即除以8

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sccb_dri_clk <=  1'b1;
        clk_cnt <= 10'd0;
    end
    else if(clk_cnt == clk_divide - 1'd1) begin
        clk_cnt <= 10'd0;
        sccb_dri_clk <= ~sccb_dri_clk;
    end
    else
        clk_cnt <= clk_cnt + 1'b1;
end

//状态机
always @(posedge sccb_dri_clk or negedge rst_n) begin
    if(!rst_n)
        state_c <= IDLE;
    else
        state_c <= state_n;
end

always @(*) begin
    case(state_c)
        IDLE: begin                             //空闲状态
           if(sccb_en)
               state_n = DEVICE;
           else
               state_n = IDLE;
        end
        DEVICE: begin                           //写器件ID
            if(state_done) begin
                if(sccb_addr[15:8]!=0)
                   state_n = ADDR_16;
                else if(sccb_addr[15:8]==0)
                   state_n = ADDR_8 ;
            end
            else
                state_n = DEVICE;
        end
        ADDR_16: begin                          //写地址高8位
            if(state_done)
                state_n = ADDR_8;
            else
                state_n = ADDR_16;
        end
        ADDR_8: begin                           //写地址低8位
            if(state_done)
                state_n = DATA;
            else
                state_n = ADDR_8;
        end
        DATA: begin                             //写数据
            if(state_done)
                state_n = STOP;
            else
                state_n = DATA;
        end
        STOP: begin                             //结束
            if(state_done)
                state_n = IDLE;
            else
                state_n = STOP ;
        end
        default:state_n= IDLE;
    endcase
end

//设计各路信号
always @(posedge sccb_dri_clk or negedge rst_n) begin
    if(!rst_n) begin
        sccb_scl    <= 1'b1;
        sda_out     <= 1'b1;
        sda_dir     <= 1'b1;
        sccb_done   <= 1'b0;
        cnt         <= 1'b0;
        state_done  <= 1'b0;
        sccb_addr_t <= 1'b0;
        sccb_data_t <= 1'b0;
    end
    else begin
        state_done  <= 1'b0;
        cnt         <= cnt + 1'b1;
        case(state_c)
            //空闲状态
            IDLE: begin
                    sccb_scl  <= 1'b1;
                    sda_out   <= 1'b1;
                    sda_dir   <= 1'b1;
                    sccb_done <= 1'b0;
                    cnt       <= 7'b0;
                    if(sccb_en) begin
                        sccb_addr_t <= sccb_addr;
                        sccb_data_t <= sccb_data;
                    end
            end
            //写器件ID
            DEVICE: begin
                case(cnt)
                    7'd1 : sda_out  <= 1'b0;
                    7'd3 : sccb_scl <= 1'b0;
                    7'd4 : sda_out  <= DEVICE_ID[7];
                    7'd5 : sccb_scl <= 1'b1;
                    7'd7 : sccb_scl <= 1'b0;
                    7'd8 : sda_out  <= DEVICE_ID[6];
                    7'd9 : sccb_scl <= 1'b1;
                    7'd11: sccb_scl <= 1'b0;
                    7'd12: sda_out  <= DEVICE_ID[5];
                    7'd13: sccb_scl <= 1'b1;
                    7'd15: sccb_scl <= 1'b0;
                    7'd16: sda_out  <= DEVICE_ID[4];
                    7'd17: sccb_scl <= 1'b1;
                    7'd19: sccb_scl <= 1'b0;
                    7'd20: sda_out  <= DEVICE_ID[3];
                    7'd21: sccb_scl <= 1'b1;
                    7'd23: sccb_scl <= 1'b0;
                    7'd24: sda_out  <= DEVICE_ID[2];
                    7'd25: sccb_scl <= 1'b1;
                    7'd27: sccb_scl <= 1'b0;
                    7'd28: sda_out  <= DEVICE_ID[1];
                    7'd29: sccb_scl <= 1'b1;
                    7'd31: sccb_scl <= 1'b0;
                    7'd32: sda_out  <= DEVICE_ID[0];
                    7'd33: sccb_scl <= 1'b1;
                    7'd35: sccb_scl <= 1'b0;
                    7'd36: begin
                           sda_dir  <= 1'b0;    //从机应答
                           sda_out  <= 1'b1;
                    end
                    7'd37: sccb_scl <= 1'b1;
                    7'd38: state_done <= 1'b1;  //状态结束
                    7'd39: begin
                           sccb_scl <= 1'b0;
                           cnt <= 1'b0;
                    end
                    default:;
                endcase
            end
            //写字地址高8位
            ADDR_16: begin
                case(cnt)
                    7'd0 : begin
                           sda_dir  <= 1'b1 ;
                           sda_out  <= sccb_addr_t[15];
                    end
                    7'd1 : sccb_scl <= 1'b1;
                    7'd3 : sccb_scl <= 1'b0;
                    7'd4 : sda_out  <= sccb_addr_t[14];
                    7'd5 : sccb_scl <= 1'b1;
                    7'd7 : sccb_scl <= 1'b0;
                    7'd8 : sda_out  <= sccb_addr_t[13];
                    7'd9 : sccb_scl <= 1'b1;
                    7'd11: sccb_scl <= 1'b0;
                    7'd12: sda_out  <= sccb_addr_t[12];
                    7'd13: sccb_scl <= 1'b1;
                    7'd15: sccb_scl <= 1'b0;
                    7'd16: sda_out  <= sccb_addr_t[11];
                    7'd17: sccb_scl <= 1'b1;
                    7'd19: sccb_scl <= 1'b0;
                    7'd20: sda_out  <= sccb_addr_t[10];
                    7'd21: sccb_scl <= 1'b1;
                    7'd23: sccb_scl <= 1'b0;
                    7'd24: sda_out  <= sccb_addr_t[9];
                    7'd25: sccb_scl <= 1'b1;
                    7'd27: sccb_scl <= 1'b0;
                    7'd28: sda_out  <= sccb_addr_t[8];
                    7'd29: sccb_scl <= 1'b1;
                    7'd31: sccb_scl <= 1'b0;
                    7'd32: begin
                           sda_dir  <= 1'b0;    //从机应答
                           sda_out  <= 1'b1;
                    end
                    7'd33: sccb_scl <= 1'b1;
                    7'd34: state_done <= 1'b1;  //状态结束
                    7'd35: begin
                           sccb_scl <= 1'b0;
                           cnt <= 1'b0;
                    end
                    default:;
                endcase
            end
            //写字地址低8位
            ADDR_8: begin
                case(cnt)
                    7'd0: begin
                           sda_dir  <= 1'b1 ;
                           sda_out  <= sccb_addr_t[7];
                    end
                    7'd1 : sccb_scl <= 1'b1;
                    7'd3 : sccb_scl <= 1'b0;
                    7'd4 : sda_out  <= sccb_addr_t[6];
                    7'd5 : sccb_scl <= 1'b1;
                    7'd7 : sccb_scl <= 1'b0;
                    7'd8 : sda_out  <= sccb_addr_t[5];
                    7'd9 : sccb_scl <= 1'b1;
                    7'd11: sccb_scl <= 1'b0;
                    7'd12: sda_out  <= sccb_addr_t[4];
                    7'd13: sccb_scl <= 1'b1;
                    7'd15: sccb_scl <= 1'b0;
                    7'd16: sda_out  <= sccb_addr_t[3];
                    7'd17: sccb_scl <= 1'b1;
                    7'd19: sccb_scl <= 1'b0;
                    7'd20: sda_out  <= sccb_addr_t[2];
                    7'd21: sccb_scl <= 1'b1;
                    7'd23: sccb_scl <= 1'b0;
                    7'd24: sda_out  <= sccb_addr_t[1];
                    7'd25: sccb_scl <= 1'b1;
                    7'd27: sccb_scl <= 1'b0;
                    7'd28: sda_out  <= sccb_addr_t[0];
                    7'd29: sccb_scl <= 1'b1;
                    7'd31: sccb_scl <= 1'b0;
                    7'd32: begin
                           sda_dir  <= 1'b0;    //从机应答
                           sda_out  <= 1'b1;
                    end
                    7'd33: sccb_scl <= 1'b1;
                    7'd34: state_done <= 1'b1;  //状态结束
                    7'd35: begin
                           sccb_scl <= 1'b0;
                           cnt <= 1'b0;
                    end
                    default:;
                endcase
            end
            //写数据
            DATA: begin
                case(cnt)
                    7'd0: begin
                           sda_out <= sccb_data_t[7];
                           sda_dir <= 1'b1;
                    end
                    7'd1 : sccb_scl <= 1'b1;
                    7'd3 : sccb_scl <= 1'b0;
                    7'd4 : sda_out  <= sccb_data_t[6];
                    7'd5 : sccb_scl <= 1'b1;
                    7'd7 : sccb_scl <= 1'b0;
                    7'd8 : sda_out  <= sccb_data_t[5];
                    7'd9 : sccb_scl <= 1'b1;
                    7'd11: sccb_scl <= 1'b0;
                    7'd12: sda_out  <= sccb_data_t[4];
                    7'd13: sccb_scl <= 1'b1;
                    7'd15: sccb_scl <= 1'b0;
                    7'd16: sda_out  <= sccb_data_t[3];
                    7'd17: sccb_scl <= 1'b1;
                    7'd19: sccb_scl <= 1'b0;
                    7'd20: sda_out  <= sccb_data_t[2];
                    7'd21: sccb_scl <= 1'b1;
                    7'd23: sccb_scl <= 1'b0;
                    7'd24: sda_out  <= sccb_data_t[1];
                    7'd25: sccb_scl <= 1'b1;
                    7'd27: sccb_scl <= 1'b0;
                    7'd28: sda_out  <= sccb_data_t[0];
                    7'd29: sccb_scl <= 1'b1;
                    7'd31: sccb_scl <= 1'b0;
                    7'd32: begin
                           sda_dir  <= 1'b0;    //从机应答
                           sda_out  <= 1'b1;
                    end
                    7'd33: sccb_scl <= 1'b1;
                    7'd34: state_done <= 1'b1;  //状态结束
                    7'd35: begin
                           sccb_scl <= 1'b0;
                           cnt  <= 1'b0;
                    end
                    default:;
                endcase
            end
            //结束
            STOP: begin
                case(cnt)
                    7'd0: begin
                           sda_dir  <= 1'b1;
                           sda_out  <= 1'b0;
                    end
                    7'd1 : sccb_scl <= 1'b1;
                    7'd3 : sda_out  <= 1'b1;
                    7'd15: state_done <= 1'b1;  //状态结束
                    7'd16: begin
                           cnt <= 1'b0;
                           sccb_done <= 1'b1;   //sccb配置完成
                    end
                    default:;
                endcase
            end
        endcase
    end
end

endmodule