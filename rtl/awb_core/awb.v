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
//	FILE: 		awb.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.16		Create
//----------------------------------------------------------------------------------------------------------
module awb#(
	parameter		FIXED_POINT_Q		=	10
								//默认 /1024 ~0.001	精度
)(
	input			clk,
	input			reset_n,
	
								//输入 (16-k) -Q -k 定点数修正参数
	input	[17:0]	i_r_gain,
	input	[17:0]	i_g_gain,
	input	[17:0]	i_b_gain,
	
	input	[2:0]	i_video_syn,
	
								//输入RGB 域视频流	R[23:16]	G[15:8]		B[7:0]
	input	[23:0]	i_data,
	output	[2:0]	o_video_sync,
	output	[23:0]	o_data
);
reg		[7:0]		r0,g0,b0;
reg		[17:0]		b_gain,r_gain,g_gain;
always @(posedge clk)
	{r_gain,g_gain,b_gain	}	<=	{i_r_gain,i_g_gain,i_b_gain};
always @(posedge clk)
	{r0,	g0,		b0		}	<=	i_data;	
reg		[3:0]		syn_v,syn_h,syn_d;

always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		syn_v	<=	0;
		syn_h	<=	0;
		syn_d	<=	0;
	end else begin
		syn_v	<=	{syn_v[2:0],	i_video_syn[2]};
		syn_d	<=	{syn_d[2:0],	i_video_syn[1]};
		syn_h	<=	{syn_h[2:0],	i_video_syn[0]};
	end
wire	[35:0]		mul_rRgain_0;
wire	[35:0]		mul_gGgain_0;
wire	[35:0]		mul_bBgain_0;

wire	[35:0]		mul_rRgain_1;
wire	[35:0]		mul_gGgain_1;
wire	[35:0]		mul_bBgain_1;
dsp_x18 u_dsp_x18_r(
	.p			(mul_rRgain_0	),
	.a			({r0,10'd0}		),
	.b			(r_gain			), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x18 u_dsp_x18_g(
	.p			(mul_gGgain_0	),
	.a			({g0,10'd0}		),
	.b			(g_gain			), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x18 u_dsp_x18_b(
	.p			(mul_bBgain_0	),
	.a			({b0,10'd0}		),
	.b			(b_gain			), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);								//做4舍去五入量化
assign			mul_rRgain_1	=	mul_rRgain_0 +(mul_rRgain_0[2*FIXED_POINT_Q -1] <<	(2*FIXED_POINT_Q));
assign			mul_gGgain_1	=	mul_gGgain_0 +(mul_gGgain_0[2*FIXED_POINT_Q -1] <<	(2*FIXED_POINT_Q));
assign			mul_bBgain_1	=	mul_bBgain_0 +(mul_bBgain_0[2*FIXED_POINT_Q -1] <<	(2*FIXED_POINT_Q));

reg	[7:0]		o_r0,o_g0,o_b0;
always @(posedge clk)
								//这里需要判断是否溢出,如果溢出置为 255
	o_r0		<=	(mul_rRgain_1[35:2*FIXED_POINT_Q +8]	==	0)	?	mul_rRgain_1[2*FIXED_POINT_Q 	+:8]	:	8'b1111_1111;
always @(posedge clk)
								//这里需要判断是否溢出,如果溢出置为 255
	o_g0		<=	(mul_gGgain_1[35:2*FIXED_POINT_Q +8]	==	0)	?	mul_gGgain_1[2*FIXED_POINT_Q  +:8]	:	8'b1111_1111;
always @(posedge clk)
								//这里需要判断是否溢出,如果溢出置为 255
	o_b0		<=	(mul_bBgain_1[35:2*FIXED_POINT_Q +8]	==	0)	?	mul_bBgain_1[2*FIXED_POINT_Q  +:8]	:	8'b1111_1111;

assign			o_data			=	{o_r0,	o_g0	,o_b0	};
assign			o_video_sync	=	{syn_v[3],syn_d[3],syn_h[3]};
endmodule