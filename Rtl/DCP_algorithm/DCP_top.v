module DCP_top
(
	input	wire			pixelclk     ,
	input	wire			reset_n      ,
	input	wire	[23:0] 	i_rgb        ,
    input	wire			i_data_valid ,  

	output  wire	[23:0] 	o_defog_rgb  ,
    output  wire			o_data_valid       
);

wire	[ 7:0] 	o_dark   		;

wire	[7: 0] 	dark_max 		;
wire	[7:0]	o_transmittance ;

wire			data_valid_1  	;
wire			data_valid_2 	;

DCP_rgb_dark u_rgb_dark
(
    .pixelclk			(pixelclk		),
	.reset_n 			(reset_n 		),
  	.i_rgb   			(i_rgb   		),
	.i_data_valid 		(i_data_valid	),   

    .o_dark  			(o_dark  		),
	.o_data_valid    	(data_valid_1	)
);	
	
DCP_transmittance_dark u_transmittance_dark
(
    .pixelclk			(pixelclk 		),
	.reset_n 			(reset_n  		),
  	.i_dark  			(o_dark   		),
	.i_data_valid 		(data_valid_1	),   

	.o_dark_max			(dark_max 		),
    .o_transmittance  	(o_transmittance),
	.o_data_valid    	(data_valid_2	)
);	

DCP_defogging u_defogging
(
    .pixelclk       	(pixelclk     	),
	.reset_n        	(reset_n      	),
  	.i_rgb          	(i_rgb        	),
	.i_transmittance	(o_transmittance),
	.i_dark_max       	(dark_max     	),
	.i_data_valid 		(data_valid_2	),   
	   
    .o_defogging    	(o_defog_rgb  	),
	.o_data_valid    	(o_data_valid	)
);
	
endmodule
