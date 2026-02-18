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
//	FILE: 		dpc_judge.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.8		Create									#00
//								2024.4.13		Fixed Logic Bugs						#01
//----------------------------------------------------------------------------------------------------------
module dpc_judge(
	input				clk,
	input				reset_n,
	
	input	[7:0]		i_dpc_threshold,
	input				i_line_vaild,
	
	input	[26:0]		i_line3_1,
	input	[26:0]		i_line3_2,
	input	[26:0]		i_line3_3,
	
	input	[7:0]		i_mid_num,
	output	[7:0]		o_judge_data,
	output				o_judge_vaild
);
reg			[8:0]		r1_0,r2_0,r3_0,r4_0,r5_0,r6_0,r7_0,r8_0,r9_0;
reg			[7:0]		thr1r0;
wire		[7:0]		sig_bit;
wire		comp_en;
always @(posedge clk )
	{r1_0,r2_0,r3_0,r4_0,r5_0,r6_0,r7_0,r8_0,r9_0	}	<=	{i_line3_1,i_line3_2,i_line3_3	};
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		thr1r0	<=	0;
	else
		thr1r0	<=	i_dpc_threshold;
assign	sig_bit	=	{	r1_0[8],r2_0[8],r3_0[8],r4_0[8],
						r6_0[8],r7_0[8],r8_0[8],r9_0[8]	};

assign	comp_en	=	sig_bit	==4'h0 | sig_bit ==4'hf;
reg		comp_en_q;	
reg			[7:0]		r1_1,r2_1,r3_1,r4_1			,r6_1,r7_1,r8_1,r9_1;
reg			[7:0]		thrlr1,thr2r1,thr3r1,thr4r1,	thr6r1,thr7r1,thr8r1,thr9r1;
								//这里的目的也许是为了增大扇出	--	改善时序
always @(posedge clk) begin
		{thrlr1,thr2r1,thr3r1,thr4r1,	thr6r1,thr7r1,thr8r1,thr9r1}	<=	{8{	thr1r0}};
		comp_en_q			<=	comp_en;
	end
								//转换为 8位无符号数
always @(posedge clk)
	if(	r1_0[8])
		r1_1	<=	~r1_0[7:0]	;
	else
		r1_1	<=	r1_0[7:0]	;
always @(posedge clk)
	if(	r2_0[8])
		r2_1	<=	~r2_0[7:0]	;
	else
		r2_1	<=	r2_0[7:0]	;
always @(posedge clk)
	if(	r3_0[8])
		r3_1	<=	~r3_0[7:0]	;
	else
		r3_1	<=	r3_0[7:0]	;
always @(posedge clk)
	if(	r4_0[8])
		r4_1	<=	~r4_0[7:0]	;
	else
		r4_1	<=	r4_0[7:0]	;
always @(posedge clk)
	if(	r6_0[8])
		r6_1	<=	~r6_0[7:0]	;
	else
		r6_1	<=	r6_0[7:0]	;
always @(posedge clk)
	if(	r7_0[8])
		r7_1	<=	~r7_0[7:0]	;
	else
		r7_1	<=	r7_0[7:0]	;
always @(posedge clk)
	if(	r8_0[8])
		r8_1	<=	~r8_0[7:0]	;
	else
		r8_1	<=	r8_0[7:0]	;
always @(posedge clk)
	if(	r9_0[8])
		r9_1	<=	~r9_0[7:0]	;
	else
		r9_1	<=	r9_0[7:0]	;

								//Just Copy from Video	:)
wire	[7:0]	flg;
assign			flg[0]		=	r1_1	>	thrlr1;
assign			flg[1]		=	r2_1	>	thr2r1;
assign			flg[2]		=	r3_1	>	thr3r1;
assign			flg[3]		=	r4_1	>	thr4r1;

assign			flg[4]		=	r6_1	>	thr6r1;
assign			flg[5]		=	r7_1	>	thr7r1;
assign			flg[6]		=	r8_1	>	thr8r1;
assign			flg[7]		=	r9_1	>	thr9r1;

reg		[7:0]	new_data;
reg		[7:0]	r5_1;
reg		[7:0]	midr0,midr1	;
reg		[2:0]	vaild_r;
wire	judge_flag;

always @(posedge clk)
	r5_1			<=	r5_0;
always @(posedge clk)
	{midr1,midr0}	<=	{midr0,i_mid_num};
always @(posedge clk)
	vaild_r			<=	{vaild_r[1:0],i_line_vaild};
always @(posedge clk)
	if(judge_flag	==1'b1)
		new_data	<=	midr1;
	else
		new_data	<=	r5_1;

assign	judge_flag		=comp_en_q &(flg ==8'hff);
assign	o_judge_data	=new_data;
assign	o_judge_vaild	=vaild_r[2];
endmodule