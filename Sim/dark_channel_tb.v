`timescale 1ns/1ps
module dark_channel_tb;

  // Parameters

  // Ports
reg  sys_clk = 0;
reg  sys_rst_n = 0;
reg [23:0] picture_data;
wire [7:0] I_dark;

dark_channel dark_channel_dut (
  .sys_clk (sys_clk ),
  .sys_rst_n (sys_rst_n ),
  .picture_data (picture_data ),
  .I_dark  ( I_dark)
);
  initial begin
    begin
      picture_data = 24'd0;
      #100
      sys_rst_n = 1;
    end
  end

  always
    #10  sys_clk = ! sys_clk ;

reg [23:0] data_mem[307199:0] ;//数据深度（个数）
integer j;
//读取数据
initial begin
$readmemh("D:/HaoGuojun/MyProject/FPGAProject/Graduation_Prj
             /static_dehazing/Doc/RGB888_mode.txt",data_mem);
             
            for (j=0;j<307200;j=j+1 )
                picture_data <= data_mem[j];


//always @(negedge sys_rst_n or posedge sys_clk)
//    if (sys_rst_n == 1'b0) 
//        picture_data <= 24'd0;
//    else
//        picture_data <= {$random}; //产生随机数
    end
endmodule

