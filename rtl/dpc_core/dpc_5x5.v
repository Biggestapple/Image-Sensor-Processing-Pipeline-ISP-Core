/**********************************************************************************************************
*
*  Copyright (c) 2026, Biggest_apple
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, this list of conditions
*     and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright notice, this list of
*     conditions and the following disclaimer in the documentation and/or other materials provided
*     with the distribution.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
*  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
*  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
***********************************************************************************************************/
//----------------------------------------------------------------------------------------------------------
//	FILE: 		dpc_5x5.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.8		Create									#00
//								2024.4.12		Continued and carefully Analyzed		#01
//----------------------------------------------------------------------------------------------------------
module	dpc_5x5(
	input			clk,
	input			reset_n,
	
	input			bayer_format,
	input	[7:0]	i_dpc_threshold,
	input	[2:0]	i_video_syn,
	
	input	[7:0]	i_data_r0,
	input	[7:0]	i_data_r1,
	input	[7:0]	i_data_r2,
	input	[7:0]	i_data_r3,
	input	[7:0]	i_data_r4,
	
	output	[2:0]	o_video_sync,
	output	[7:0]	o_data
);
								//声明矩阵锁存器
reg		[7:0]		r1_1,r1_2,r1_3,r1_4,r1_5;
reg		[7:0]		r2_1,r2_2,r2_3,r2_4,r2_5;
reg		[7:0]		r3_1,r3_2,r3_3,r3_4,r3_5;
reg		[7:0]		r4_1,r4_2,r4_3,r4_4,r4_5;
reg		[7:0]		r5_1,r5_2,r5_3,r5_4,r5_5;

always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r1_1,r1_2,r1_3,r1_4,r1_5	}	<=	0;
	else
		{r1_1,r1_2,r1_3,r1_4,r1_5	}	<=	{r1_2,r1_3,r1_4,r1_5,i_data_r0	};
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r2_1,r2_2,r2_3,r2_4,r2_5	}	<=	0;
	else
		{r2_1,r2_2,r2_3,r2_4,r2_5	}	<=	{r2_2,r2_3,r2_4,r2_5,i_data_r1	};
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r3_1,r3_2,r3_3,r3_4,r3_5	}	<=	0;
	else
		{r3_1,r3_2,r3_3,r3_4,r3_5	}	<=	{r3_2,r3_3,r3_4,r3_5,i_data_r2	};
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r4_1,r4_2,r4_3,r4_4,r4_5	}	<=	0;
	else
		{r4_1,r4_2,r4_3,r4_4,r4_5	}	<=	{r4_2,r4_3,r4_4,r4_5,i_data_r3	};
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r5_1,r5_2,r5_3,r5_4,r5_5	}	<=	0;
	else
		{r5_1,r5_2,r5_3,r5_4,r5_5	}	<=	{r5_2,r5_3,r5_4,r5_5,i_data_r4	};

reg		[11:0]		syn_v,syn_h,syn_d;

always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		syn_v	<=	0;
		syn_h	<=	0;
		syn_d	<=	0;
	end else begin
		syn_v	<=	{syn_v[10:0],	i_video_syn[2]};
		syn_d	<=	{syn_d[10:0],	i_video_syn[1]};
		syn_h	<=	{syn_h[10:0],	i_video_syn[0]};
	end

wire	syn_d_pos	=	(syn_d[4:3]	==	2'b01);
wire	syn_v_neg	=	(syn_v[4:3]	==	2'b10);

reg					odd_pixel,odd_line;
reg		[7:0]		r1_1r0,r1_3r0,r1_5r0;
reg		[7:0]		r3_1r0,r3_3r0,r3_5r0;
reg		[7:0]		r5_1r0,r5_3r0,r5_5r0;

always @(posedge clk or negedge reset_n)
	if(~reset_n)
		odd_pixel	<=	1'b0;
	else if(syn_d_pos)
		odd_pixel	<=	~bayer_format;
	else if(syn_d[4])
								//第一个像素位置为 (1,1)
		odd_pixel	<=	~odd_pixel;

always @(posedge clk or negedge reset_n)
	if(~reset_n)
		odd_line	<=	1'b0;
	else if(syn_v_neg)
		odd_line	<=	1'b0;
	else if(syn_d_pos)
		odd_line	<=	~odd_line;
		
always @(posedge clk)
								/*
									B G B G B G
									G R G R G R
									B G B G B G
									G R G R G R
									B G B G B G
								*/
	if(odd_pixel	==	odd_line) begin
								//B/R Formula	Note:Just need one clock
		{r1_1r0,r1_3r0,r1_5r0}	<=	{r1_1,r1_3,r1_5};
		{r3_1r0,r3_3r0,r3_5r0}	<=	{r3_1,r3_3,r3_5};
		{r5_1r0,r5_3r0,r5_5r0}	<=	{r5_1,r5_3,r5_5};
	end else begin
								//G Formula
		{r1_3r0}				<=	{r1_3};
		{r1_1r0,r1_5r0}			<=	{r2_2,r2_4};
		{r3_1r0,r3_3r0,r3_5r0}	<=	{r3_1,r3_3,r3_5};
		{r5_1r0,r5_5r0}			<=	{r4_2,r4_4};
		{r5_3r0}				<=	{r5_3};
	end

wire	signed 	[8:0]		dlt1,dlt2,dlt3,dlt4,dlt5,dlt6,dlt7,dlt8,dlt9	;
wire			[7:0]		mid_num;
								//简单计算中心像素与周围像素的差值
delta_3x3 u_delta_3x3(
	.clk				(clk					),
	.reset_n			(reset_n				),
	
	.i_line_vaild		(syn_d[5]				),
//	.o_line_valid		(						),
								//输入8位无符号数
	.i_line3_1			({r1_1r0,r1_3r0,r1_5r0}	),
	.i_line3_2			({r3_1r0,r3_3r0,r3_5r0}	),
	.i_line3_3			({r5_1r0,r5_3r0,r5_5r0}	),
	
								//输出9位有符号数
	.o_line3_1			({dlt1,dlt2,dlt3}		),
	.o_line3_2			({dlt4,dlt5,dlt6}		),
	.o_line3_3			({dlt7,dlt8,dlt9}		)
	
);
								//寻找中间值进行比较分析
mid_3x3	u_mid_3x3(
	.clk				(clk					),
	.reset_n			(reset_n				),
	
	.i_line_vaild		(syn_d[5]				),
//	.o_data_valid		(						),
								//输入8位无符号数
	.i_line3_1			({r1_1r0,r1_3r0,r1_5r0}	),
	.i_line3_2			({r3_1r0,r3_3r0,r3_5r0}	),
	.i_line3_3			({r5_1r0,r5_3r0,r5_5r0}	),
	
								//输出矩阵中值
	.o_mid_data			(mid_num				)

);
								//数据替换判断模块
dpc_judge	u_dpc_judge(
	.clk				(clk					),
	.reset_n			(reset_n				),
	
	.i_dpc_threshold	(i_dpc_threshold		),
	.i_line_vaild		(syn_d[8]				),
								//需要 3clks	...	...
	
	.i_line3_1			({dlt1,dlt2,dlt3}		),
	.i_line3_2			({dlt4,dlt5,dlt6}		),
	.i_line3_3			({dlt7,dlt8,dlt9}		),
	
	.i_mid_num			(mid_num				),
	.o_judge_data		(o_data					),
	.o_judge_vaild		(						)
);

assign		o_video_sync	=	{syn_v[11],		syn_d[11],		syn_h[11]};
endmodule