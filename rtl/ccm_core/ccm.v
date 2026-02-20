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
//	FILE: 		ccm.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.16		Create
//----------------------------------------------------------------------------------------------------------
module ccm(
	input			clk,
	input			reset_n,
	
	input	[8:0]	i_ccm_1m1,	//输入9位定点小数，注意为有符号数	- 2 ~ +2
	input	[8:0]	i_ccm_1m2,
	input	[8:0]	i_ccm_1m3,
	
	input	[8:0]	i_ccm_2m1,
	input	[8:0]	i_ccm_2m2,
	input	[8:0]	i_ccm_2m3,
	
	input	[8:0]	i_ccm_3m1,
	input	[8:0]	i_ccm_3m2,
	input	[8:0]	i_ccm_3m3,
	
	input	[2:0]	i_video_syn,
	
								//输入RGB 域视频流	R[23:16]	G[15:8]		B[7:0]
	input	[23:0]	i_data,
	output	[2:0]	o_video_sync,
	output	[23:0]	o_data
);
reg			[8:0]	ccm_1m1,ccm_1m2,ccm_1m3,ccm_2m1,ccm_2m2,ccm_2m3,ccm_3m1,ccm_3m2,ccm_3m3;
always @(posedge clk)
	{ccm_1m1,	ccm_1m2,	ccm_1m3,
	ccm_2m1,	ccm_2m2,	ccm_2m3,
	ccm_3m1,	ccm_3m2,	ccm_3m3}	<=	{i_ccm_1m1,		i_ccm_1m2,	i_ccm_1m3,
											i_ccm_2m1,		i_ccm_2m2,	i_ccm_2m3,
											i_ccm_3m1,		i_ccm_3m2,	i_ccm_3m3};
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
reg		[7:0]	r0,g0,b0;		//注意 DSP输出延时一个周期
								//矩阵加法操作延时一个周期
always @(posedge clk)
	{r0,g0,b0}	<=	i_data;		//最高位为符号位
wire	[17:0]	mul_ccm1_1,mul_ccm1_2,mul_ccm1_3,
				mul_ccm2_1,mul_ccm2_2,mul_ccm2_3,
				mul_ccm3_1,mul_ccm3_2,mul_ccm3_3;
dsp_x9 u_dsp_x9_cmm1_1(
	.p			(mul_ccm1_1		),
	.a			({1'b0,r0}		),
	.b			(ccm_1m1		), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9 u_dsp_x9_cmm1_2(
	.p			(mul_ccm1_2		),
	.a			({1'b0,g0}		),
	.b			(ccm_1m2		), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9 u_dsp_x9_cmm1_3(
	.p			(mul_ccm1_3		),
	.a			({1'b0,b0}		),
	.b			(ccm_1m3		), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);

dsp_x9 u_dsp_x9_cmm2_1(
	.p			(mul_ccm2_1		),
	.a			({1'b0,r0}		),
	.b			(ccm_2m1		), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9 u_dsp_x9_cmm2_2(
	.p			(mul_ccm2_2		),
	.a			({1'b0,g0}		),
	.b			(ccm_2m2		), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9 u_dsp_x9_cmm2_3(
	.p			(mul_ccm2_3		),
	.a			({1'b0,b0}		),
	.b			(ccm_2m3		), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);

dsp_x9 u_dsp_x9_cmm3_1(
	.p			(mul_ccm3_1		),
	.a			({1'b0,r0}		),
	.b			(ccm_3m1		), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9 u_dsp_x9_cmm3_2(
	.p			(mul_ccm3_2		),
	.a			({1'b0,g0}		),
	.b			(ccm_3m2		), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9 u_dsp_x9_cmm3_3(
	.p			(mul_ccm3_3		),
	.a			({1'b0,b0}		),
	.b			(ccm_3m3		), 
	.cea		(syn_d[0]		), 
	.ceb		(syn_d[0]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
reg			[7:0]	o_r0,	o_g0,	o_b0;
wire signed	[19:0]	o_r0_d,	o_g0_d,	o_b0_d;
assign			o_r0_d	=	mul_ccm1_1 +mul_ccm1_2	+mul_ccm1_3;
assign			o_g0_d	=	mul_ccm2_1 +mul_ccm2_2	+mul_ccm2_3;
assign			o_b0_d	=	mul_ccm3_1 +mul_ccm3_2	+mul_ccm3_3;
								//构造加法器，考虑符号位处理
								//ccm_xmx	={SIGNED_BIT[8],	INTEGER_BIT[7],		FIXED_BITSs[6:0]	};
								//r0		={1'b0,				INTEGER_BIT[7:0]						};
always @(posedge clk)
	o_r0		<=	(o_r0_d[19]	==	1'b1		)	?	8'b0:
								//判断是否溢出，如果溢出置为 255
					(o_r0_d[18:15] != 0			)	?	8'b1111_1111	:o_r0_d[14:7];
always @(posedge clk)
	o_g0		<=	(o_g0_d[19]	==	1'b1		)	?	8'b0:
								//判断是否溢出，如果溢出置为 255
					(o_g0_d[18:15] != 0			)	?	8'b1111_1111	:o_g0_d[14:7];
always @(posedge clk)
	o_b0		<=	(o_b0_d[19]	==	1'b1		)	?	8'b0:
								//判断是否溢出，如果溢出置为 255
					(o_b0_d[18:15] != 0			)	?	8'b1111_1111	:o_b0_d[14:7];

assign			o_data			=	{o_r0,	o_g0	,o_b0	};
assign			o_video_sync	=	{syn_v[3],syn_d[3],syn_h[3]};
endmodule