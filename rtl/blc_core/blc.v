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
//	FILE: 		blc.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.8		Create
//-----------------------------------------------------------------------------------------------------------
module blc(
	input			clk,
	input			reset_n,
	
	input	[2:0]	i_bayer_format,

	input	[7:0]	i_blc_r_value,
	input	[7:0]	i_blc_b_value,
	input	[7:0]	i_blc_gr_value,
	input	[7:0]	i_blc_gb_value,
	
	input	[2:0]	i_video_syn,
	
	input	[7:0]	i_data,
	output	[2:0]	o_video_sync,
	output	[7:0]	o_data
);

reg		[2:0]		syn_v,syn_h,syn_d;

always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		syn_v	<=	0;
		syn_h	<=	0;
		syn_d	<=	0;
	end else begin
		syn_v	<=	{syn_v[1:0],	i_video_syn[2]};
		syn_d	<=	{syn_d[1:0],	i_video_syn[1]};
		syn_h	<=	{syn_h[1:0],	i_video_syn[0]};
	end

wire	syn_d_neg	=	(syn_d[2:1]	==	2'b10);
reg		odd_line;
reg		[15:0]			delta_t1,delta_t2;
reg		[2:0]			bayer_format;
reg		[7:0]			delta_r,delta_gr,delta_gb,delta_b;
always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		bayer_format						<=	0;
		{delta_r,delta_gr,delta_gb,delta_b}	<=	0;
	end else begin
		bayer_format		<=	i_bayer_format;
		{delta_r,delta_gr,delta_gb,delta_b}
							<=	{i_blc_r_value,i_blc_gr_value,i_blc_b_value,i_blc_gb_value};
	end

always @(posedge clk or negedge reset_n)
	if(~reset_n)
		odd_line	<=	1'b0;
	else if(syn_v[0])
		odd_line	<=	1'b1;
								//第一行为奇数行
	else if(syn_d_neg)
		odd_line	<=	~odd_line;
								//下一行即为偶数行

								//根据不同的bayer数据格式选择减数因子
always @(posedge clk)
	case(bayer_format)
		3'b000:	{delta_t1,delta_t2}	<=	{delta_b,delta_gb,delta_gr,delta_r};
								//B G G R
		3'b001:
				{delta_t1,delta_t2}	<=	{delta_gb,delta_b,delta_r,delta_gr};
								//G B R G
		3'b010:
				{delta_t1,delta_t2}	<=	{delta_r,delta_gr,delta_gb,delta_b};
								//R G G B
		3'b011:
				{delta_t1,delta_t2}	<=	{delta_gr,delta_r,delta_b,delta_gb};
								//G R B G
		default:begin
				{delta_t1,delta_t2}	<=	'h0;
				$error("%m: at time %t	Invaild Bayer Formula.",$time);
			end
	endcase


reg		[15:0]			delta_dat;
always @(posedge clk)
	if(odd_line &&(~	syn_d[0])		)
		delta_dat		<=	delta_t1;
	else if((~odd_line)&&(~	syn_d[0]) 	)
		delta_dat		<=	delta_t2;
	else if(syn_d[0]					)
		delta_dat		<=	{delta_dat[7:0],delta_dat[15:8]};
								//需要轮换 R/B 与 G 位置

reg			[7:0]			r0;
reg	signed	[8:0]		sub_r0;
always @(posedge clk)
	r0					<=	i_data;
								//Noops	...	...
always @(posedge clk)
	if(syn_d[0])
		sub_r0			<=	{1'b0,r0}	-	{1'b0,delta_dat[15:8]};

reg			[7:0]		blc_dat;
always @(posedge clk)
	if(sub_r0[8])
		blc_dat			<=	0;
								//检测是否超限,如果超限置为 0
	else
		blc_dat			<=	{sub_r0[7:0]};

assign	o_data			=	blc_dat;
								//Here	...

assign	o_video_sync	=	{syn_v[2],syn_d[2],syn_h[2]};
endmodule