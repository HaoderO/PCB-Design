module transmissivity   //透射率
(
//    input   wire            sys_clk     ,
//    input   wire            sys_rst_n   ,
    input   wire    [7:0]   data_in   ,

    output  wire    [7:0]   t         
);

//将大气光值A看作常量255
//雾的保留系数w取0.95
assign t = 8'd242 - data_in;

endmodule