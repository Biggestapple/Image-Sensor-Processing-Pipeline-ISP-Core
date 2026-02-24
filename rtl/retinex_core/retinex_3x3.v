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
//	FILE: 		retinex_3x3.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.8		Create									#00
//----------------------------------------------------------------------------------------------------------
module retinex_3x3#(
	parameter		COL_OFFSET		='d2
								//颜色偏移参数
)(
	input			clk,
	input			reset_n,
	
	input	[1:0]	i_blur_format,
	input	[2:0]	i_video_syn,
	
	input	[7:0]	i_gray_data,
	output	[2:0]	o_video_sync,
	output	[7:0]	o_data

);
								//声明矩阵锁存器
reg		[7:0]		r1_1,r1_2,r1_3;
reg		[7:0]		r2_1,r2_2,r2_3;
reg		[7:0]		r3_1,r3_2,r3_3;
								//取3x3矩阵框
wire	[2:0]		line_buffer_fifo_3x3_syn_1;
wire	[7:0]		o_line_data0_1,o_line_data1_1,o_line_data2_1;							
wire	[1:0]		fifo_lb_empty_1,fifo_lb_full_1;
wire	[7:0]		i_fifo_data;
assign				i_fifo_data		=	i_gray_data +	COL_OFFSET;
line_buffer_fifo_3x3 u_line_buffer_3x3
(
	.clk				(clk			),
	.reset_n			(reset_n		),
	
	.i_de_vaild			(1'b1			),
	.i_data				(i_fifo_data	),
	.i_video_syn		(i_video_syn	),
	
	.o_video_syn		(line_buffer_fifo_3x3_syn_1
						),
	.o_line_data		({	o_line_data0_1,
							o_line_data1_1,
							o_line_data2_1}
						),
	
	.o_fifo_lb_empty	(fifo_lb_empty_1),
	.o_fifo_lb_full		(fifo_lb_full_1	)
);
reg		[8:0]		syn_v,syn_h,syn_d;

always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		syn_v	<=	0;
		syn_h	<=	0;
		syn_d	<=	0;
	end else begin
		syn_v	<=	{syn_v[7:0],	line_buffer_fifo_3x3_syn_1[2]};
		syn_d	<=	{syn_d[7:0],	line_buffer_fifo_3x3_syn_1[1]};
		syn_h	<=	{syn_h[7:0],	line_buffer_fifo_3x3_syn_1[0]};
	end
								//需要3 clks 装载移位寄存器
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r1_1,r1_2,r1_3}	<=	0;
	else
		{r1_1,r1_2,r1_3}	<=	{r1_2,r1_3,o_line_data0_1	};
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r2_1,r2_2,r2_3}	<=	0;
	else
		{r2_1,r2_2,r2_3}	<=	{r2_2,r2_3,o_line_data1_1	};
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{r3_1,r3_2,r3_3}	<=	0;
	else
		{r3_1,r3_2,r3_3}	<=	{r3_2,r3_3,o_line_data2_1	};
								//得到矩阵形式后进行Gaussian滤波
reg		[7:0]			l_blur_data;
reg		[7:0]			l_gray_data;
always @(posedge clk)
	l_gray_data			<=		r2_2;
always @(posedge clk)
	case(i_blur_format)
		2'b00:					
								/*
									1/16	1/16	1/16
									1/16	1/2		1/16
									1/16	1/16	1/16
								*/
				l_blur_data		<=	(({3'b0,	r1_1 }+{3'b0,	r1_2} +{3'b0,	r1_3 }+{3'b0,	r2_1 }
									+{3'b0,		r2_3 }+{3'b0,	r3_1 }+{3'b0,	r3_2 }+{3'b0,	r3_3}) >>4 )+ r2_2 >>1;
		2'b01:
								/*
									1/16	1/8		1/16
									1/8		1/4		1/8
									1/16	1/8		1/16
								*/
				l_blur_data		<=		(({2'b0,r1_1} +{2'b0,r1_3} +{2'b0,r3_1} +{2'b0,r3_3}) >>4)
									+	(({2'b0,r1_2} +{2'b0,r2_1} +{2'b0,r2_3} +{2'b0,r3_2}) >>3)
									+	(r2_2>>2												 );
		
								/*
									0		1/8		0
									1/8		1/2		1/8
									0		1/8		0
								*/
		2'b10:
				l_blur_data		<=
										(({2'b0,r1_2} +{2'b0,r2_1} +{2'b0,r2_3} +{2'b0,r3_2}) >>3)
									+	(r2_2>>1												 );
								/*
									0		0		0
									0		1		0
									0		0		0
								*/
		default:l_blur_data		<=	r2_2;
	endcase
reg		[8:0]			dst_blur_data;
reg		[8:0]			dst_gray_data;
wire	[8:0]			w_dst_blur_data;
wire	[8:0]			w_dst_gray_data;
								//已经得到滤波后数据流	,进行log查找表运算	9Kit -->	9位无符号定点数
/*
retinex_log_lut	retinex_log_lut0
(
	.doa			(w_dst_blur_data),
	.addra			(l_blur_data	), 
	.clka			(clk			)
);
								//4clks
retinex_log_lut	retinex_log_lut1
(
	.doa			(w_dst_gray_data),
	.addra			(l_gray_data	), 
	.clka			(clk			)
);
*/
								//For Debugger	..
reg		[8:0]		retinex_log_lut	[0:255];
reg		[7:0]		retinex_e_lut	[0:1023];
initial begin
	$readmemh		("retinex_log.dat"	, retinex_log_lut,	0,255		);
	$readmemh		("retinex_e.dat"	, retinex_e_lut,	0,1023		);
end
assign				w_dst_blur_data	=retinex_log_lut[l_blur_data];
assign				w_dst_gray_data =retinex_log_lut[l_gray_data];

always @(posedge clk) begin
	dst_blur_data	<=	w_dst_blur_data;
	dst_gray_data	<=	w_dst_gray_data;
								//得到log形式,注意小数位数 ~6
end
								//5clks
reg		[17:0]			dst_Ixlt_data;
reg		[8:0]			dst_gray_data_r1;
								//执行一次乘法操作得到 Ixl
always @(posedge clk)
		dst_Ixlt_data		<=	dst_blur_data *dst_gray_data;
								//整数6位 ,小数12位
always @(posedge clk)
		dst_gray_data_r1	<=	dst_gray_data;
								//6clks
								//做一次减法得到重构图像
reg		signed 	[18:0]			log_r_data0;
always @(posedge clk)
		log_r_data0			<=	dst_Ixlt_data	-	{3'b0,dst_gray_data_r1,6'b0};
								//注意这里的位数对齐操作
								//7clks
reg		[9:0]					log_r_data1;
always @(posedge clk)
	if		(log_r_data0[18] ==1'b1		)
		log_r_data1			<=	'd0;
	else if	(log_r_data0[18:16] ==3'b000)
		log_r_data1			<=	log_r_data0[15:6];
	else
		log_r_data1			<=	{10{1'b1}};
								//三位整数6位小数
								//8clks
wire	[7:0]		w_o_gray_data;
reg		[7:0]		o_gray_data;
								//重构原始图像归一化
/*
retinex_norm_lut	retinex_norm_lut0
(
	.doa			(w_o_gray_data	),
	.addra			(log_r_data1	), 
	.clka			(clk			)
);
*/
								//For Debugger ..
assign				w_o_gray_data	=	retinex_e_lut[log_r_data1];

always @(posedge clk)
	o_gray_data		<=	w_o_gray_data;
								//9clks

assign				o_data			=	o_gray_data;
assign				o_video_sync	=	{syn_v[8],syn_d[8],syn_h[8]	};
endmodule