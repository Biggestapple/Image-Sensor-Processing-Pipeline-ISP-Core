//----------------------------------------------------------------------------------------------------------
//	FILE: 		delta_3x3.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.8		Create									#00
//-----------------------------------------------------------------------------------------------------------
module	delta_3x3(
	input			clk,
	input			reset_n,
	
	input			i_line_vaild,
	output			o_line_valid,
								//输入8位无符号数
	input	[23:0]	i_line3_1,
	input	[23:0]	i_line3_2,
	input	[23:0]	i_line3_3,
	
								//输出9位有符号数
	output	[26:0]	o_line3_1,
	output	[26:0]	o_line3_2,
	output	[26:0]	o_line3_3
	
);

reg		[7:0]	r1_1,r1_2,r1_3;
reg		[7:0]	r2_1,r2_2,r2_3;
reg		[7:0]	r3_1,r3_2,r3_3;

reg		data_vaild;
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		data_vaild	<=	1'b0;
	else
		data_vaild	<=	i_line_vaild;

always @(posedge clk)
	{r1_1,r1_2,r1_3	}	<=	{i_line3_1};
always @(posedge clk)
	{r2_1,r2_2,r2_3	}	<=	{i_line3_2};
always @(posedge clk)
	{r3_1,r3_2,r3_3	}	<=	{i_line3_3};

reg		[7:0]	r2_2_1,r2_2_2,r2_2_3;
always @(posedge clk)
	{r2_2_1,r2_2_2,r2_2_3}	<=	{3{i_line3_2[15:8]}	};

reg signed	[8:0]	o_dat1,o_dat2,o_dat3,o_dat4,o_dat5,o_dat6,o_dat7,o_dat8,o_dat9;
reg signed	[8:0]	o_dat1_r1,o_dat2_r1,o_dat3_r1,o_dat4_r1,o_dat5_r1,o_dat6_r1,o_dat7_r1,o_dat8_r1,o_dat9_r1;
								//建立延时一个周期
always @(posedge clk)
	if(data_vaild) begin
		o_dat1	<=	r2_2	-	r1_1;
		o_dat2	<=	r2_2	-	r1_2;
		o_dat3	<=	r2_2_1	-	r1_3;
		o_dat4	<=	r2_2_1	-	r2_1;
		o_dat6	<=	r2_2_2	-	r2_3;
		o_dat7	<=	r2_2_2	-	r3_1;
		o_dat8	<=	r2_2_3	-	r3_2;
		o_dat9	<=	r2_2_3	-	r3_3;
	end
always @(posedge clk)
	{o_dat1_r1,o_dat2_r1,o_dat3_r1,o_dat4_r1,o_dat6_r1,o_dat7_r1,o_dat8_r1,o_dat9_r1}	<=	
	{o_dat1,o_dat2,o_dat3,o_dat4,o_dat6,o_dat7,o_dat8,o_dat9							};
reg	[2:0]	data_vaild_r;
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		data_vaild_r	<=	3'b000;
								//Noops... ...
	else
		data_vaild_r	<=	{data_vaild_r[1:0],i_line_vaild};

								//注意这里将中值延时 2clks
reg	[7:0]	r2_2_q0;
reg	[7:0]	r2_2_q1;
reg	[7:0]	r2_2_q2;
always @(posedge clk) begin
	r2_2_q0	<=	r2_2;
	r2_2_q1	<=	r2_2_q0;
	r2_2_q2	<=	r2_2_q1;
end
								//快速中值法至少需要三个周期
assign	o_line3_1	=	{o_dat1_r1,	o_dat2_r1,			o_dat3_r1}	;
assign	o_line3_2	=	{o_dat4_r1,	{1'b0,r2_2_q2},		o_dat6_r1}	;
assign	o_line3_3	=	{o_dat7_r1,	o_dat8_r1,			o_dat9_r1}	;
assign	o_line_valid=	data_vaild_r[2]								;
endmodule