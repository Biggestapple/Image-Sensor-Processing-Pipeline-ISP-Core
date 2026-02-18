/**********************************************************************************************************
*
*  Copyright (c) 2025, Biggestapple
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
//	FILE: 		cfa.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	Bayer2RGB Convertor
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.8		Create
//----------------------------------------------------------------------------------------------------------
module cfa(
	input			clk,
	input			reset_n,
	
	input			bayer_format,
	
	input	[2:0]	i_video_syn,
	
	input	[7:0]	i_data_r0,
	input	[7:0]	i_data_r1,
	input	[7:0]	i_data_r2,
	
	output	[2:0]	o_video_syn,
	
	output	[23:0]	o_rgb_data
);
								//声明矩阵锁存器
reg		[7:0]		r1_1,r1_2,r1_3;
reg		[7:0]		r2_1,r2_2,r2_3;
reg		[7:0]		r3_1,r3_2,r3_3;
								//需要3 clks 装载移位寄存器
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r1_1,r1_2,r1_3}	<=	0;
	else
		{r1_1,r1_2,r1_3}	<=	{r1_2,r1_3,i_data_r0	};
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r2_1,r2_2,r2_3}	<=	0;
	else
		{r2_1,r2_2,r2_3}	<=	{r2_2,r2_3,i_data_r1	};
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r3_1,r3_2,r3_3}	<=	0;
	else
		{r3_1,r3_2,r3_3}	<=	{r3_2,r3_3,i_data_r2	};
reg					odd_pixel,odd_line;
reg		[3:0]		syn_v,syn_h,syn_d;

always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		syn_v	<=	0;
		syn_h	<=	0;
		syn_d	<=	0;
	end else begin
		syn_v	<=	{syn_v[3:0],	i_video_syn[2]};
		syn_d	<=	{syn_d[3:0],	i_video_syn[1]};
		syn_h	<=	{syn_h[3:0],	i_video_syn[0]};
	end

wire	syn_d_neg	=	(syn_d[2:1]	==	2'b10);
wire	syn_v_neg	=	(syn_d[2:1]	==	2'b10);
wire	syn_d_pos	=	(syn_d[2:1]	==	2'b01);

always @(posedge clk or negedge reset_n)
	if(~reset_n)
		odd_line	<=	1'b0;
	else if(syn_v[0]	)
		odd_line	<=	1'b1;
								//第一行为奇数行
	else if(syn_d_neg	)
		odd_line	<=	~odd_line;
always @(posedge  clk or negedge reset_n)
	if(~reset_n)
		odd_pixel	<=	1'b0;
	else if(syn_d_pos)
		odd_pixel	<=	~bayer_format;
	else if(syn_d[2])
		odd_pixel	<=	~odd_pixel;

reg		[7:0]		r0,g0,b0;
								//注意这里位数的变换
wire	[9:0]		ss_sum_ff_0	=	r1_1 +r1_3 +r3_1+r3_3;
wire	[9:0]		ss_sum_ff_1 =	r2_1 +r2_3 +r1_2+r3_2;
wire	[8:0]		ss_sum_fg_0	=	r2_1	+	r2_3;
wire	[8:0]		ss_sum_fg_1	=	r1_2	+	r3_2;
always @(posedge clk)
	case({odd_line,odd_pixel})
		2'b11:begin
				r0		<=	r2_2;
				g0		<=	ss_sum_ff_1	>>	2;
				b0		<=	ss_sum_ff_0	>>	2;
			end
								//B	 G	B	
								//G  R  G
								//B  G  B
		2'b10:begin
				r0		<=	ss_sum_fg_0	>>	1;
				g0		<=	r2_2;
				b0		<=	ss_sum_fg_1	>>	1;		
			end
								//G  B  G	
								//R  G  R
								//G  B  G
		2'b00:begin
				r0		<=	ss_sum_ff_0	>>	2;
				g0		<=	ss_sum_ff_1	>>	2;
				b0		<=	r2_2;
								//R  G  R	
								//G  B  G
								//R  G  R
			end
		2'b01:begin
				r0		<=	ss_sum_fg_1	>>	1;
				g0		<=	r2_2;
				b0		<=	ss_sum_fg_0	>>	1;	
		
			end
								//G  R  G	
								//B  G  B
								//G  R  G
/*		
		default:begin
				{r0,g0,b0}		<=	'h0;
				$error("%m: at time %t	Invaild Bayer Formula.",%time);
			end
*/
	endcase
								//建立输出信号
assign		o_video_syn		=	{syn_v[3],		syn_d[3],		syn_h[3]	};
assign		o_rgb_data		=	{r0,	g0,		b0							};
endmodule