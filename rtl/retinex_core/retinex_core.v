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
//	FILE: 		retinex_core.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.8		Create									#00
//----------------------------------------------------------------------------------------------------------
module		retinex_core(
	input			clk,
	input			reset_n,
	
	input	[1:0]	i_blur_format,
	input	[2:0]	i_video_syn,
	
	input	[23:0]	i_data,
	output	[2:0]	o_video_sync,
	output	[23:0]	o_data

);
reg		[1:0]	blur_format;
wire	[7:0]	o_r,o_g,o_b;
always @(posedge clk)
	blur_format		<=	i_blur_format;
								//受限于乘法器个数仅仅实现单通道混合
								//第一步计算高斯滤波后函数
								//对三个通道进行处理
retinex_3x3 retinex_3x3_r(
	.clk			(clk			),
	.reset_n		(reset_n		),
	
	.i_blur_format	(blur_format	),
	.i_video_syn	(i_video_syn	),
	
	.i_gray_data	(i_data[23:16]	),
	.o_video_sync	(o_video_sync	),
	.o_data			(o_r			)

);
								//5 *9Kb +1*dsp
retinex_3x3 retinex_3x3_g(
	.clk			(clk			),
	.reset_n		(reset_n		),
	
	.i_blur_format	(blur_format	),
	.i_video_syn	(i_video_syn	),
	
	.i_gray_data	(i_data[15:8]	),
	.o_video_sync	(				),
	.o_data			(o_g			)

);
retinex_3x3 retinex_3x3_b(
	.clk			(clk			),
	.reset_n		(reset_n		),
	
	.i_blur_format	(blur_format	),
	.i_video_syn	(i_video_syn	),
	
	.i_gray_data	(i_data[7:0]	),
	.o_video_sync	(				),
	.o_data			(o_b			)

);

assign				o_data	={o_r,		o_g,	o_b};
endmodule