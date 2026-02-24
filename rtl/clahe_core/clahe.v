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
//	FILE: 		gamma.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.27		Create
//								2024.4.30		Modifyed for GRAY8-Formula Alg	#0
//----------------------------------------------------------------------------------------------------------
`timescale 1ns / 1ps
module clahe#(
	parameter		[15:0]	x_res		=640,
	parameter		[15:0]	y_res		=480,
	parameter		FILENAME_YQ			="",
	parameter		FILENAME_XQ			=""
)(
	input			clk,
	input			reset_n,
	
	input	[2:0]	i_video_syn,
	
								//分块查找表配置端口,目前默认x16分块
								/*内存空间分布如下:
									----R-------R---- 	TOTAL:8KB
									gamma_r_1_1			0.5KB
									...			...
									gamma_r_4_4			0.5KB
								*/
	input	[1:0]	i_gammaTable_sel,
	input	[7:0]	i_gamma_wdata,
	input			i_gammaSet_en,
	input	[11:0]	i_gamma_addr,
								//输入RGB 域视频流	R[23:16]	G[15:8]		B[7:0]
	input	[23:0]	i_data,
	output	[2:0]	o_video_sync,
	output	[23:0]	o_data
);
reg			[1:0]	gammaTable_sel;
reg			[7:0]	gamma_wdata;
reg					gammaSet_en;
reg			[11:0]	gamma_addr;

always @(posedge clk) begin
			gammaTable_sel		<=	i_gammaTable_sel;
			gamma_wdata			<=	i_gamma_wdata;
			gammaSet_en			<=	i_gammaSet_en;
			gamma_addr			<=	i_gamma_addr;
end
parameter	[7:0]	TILE_WIDTH		=x_res	/4;
parameter	[7:0]	TILE_HEIGHT		=y_res	/4;

reg			[7:0]	r0,g0,b0;
always @(posedge clk)
		{r0,	g0,		b0	}		<=	i_data;
								//1 clk
reg		[8:0]		syn_v,syn_h,syn_d;

always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		syn_v	<=	0;
		syn_h	<=	0;
		syn_d	<=	0;
	end else begin
		syn_v	<=	{syn_v[7:0],	i_video_syn[2]};
		syn_d	<=	{syn_d[7:0],	i_video_syn[1]};
		syn_h	<=	{syn_h[7:0],	i_video_syn[0]};
	end
reg		[15:0]		row_cnt;
reg		[15:0]		col_cnt;
wire	syn_v_pos	=(syn_v[1:0]	==2'b01	)	;
wire	syn_d_neg	=(syn_d[1:0]	==2'b10	)	;
always @(posedge clk or negedge reset_n)
	if(~reset_n	||	syn_v_pos) begin
								//默认1行1列
		row_cnt		<=	'd0;
		col_cnt		<=	'd0;
	end else begin
								//行列计数器,用于标记当前的像素位置
		if(syn_d_neg) begin
			row_cnt	<=	row_cnt +1;
								//行计数加一
			col_cnt	<=	0;
								//列计数复位
		end
		if(syn_d[0])	col_cnt	<=	col_cnt +1;
								//1clk
	end
								//判断当前像素所在 TILE
wire			is_x_in_range_1	=	(col_cnt	<	TILE_WIDTH	);
wire			is_x_in_range_2	=	(col_cnt	>=	1*TILE_WIDTH)&&(col_cnt	<	2*TILE_WIDTH);
wire			is_x_in_range_3	=	(col_cnt	>=	2*TILE_WIDTH)&&(col_cnt	<	3*TILE_WIDTH);
wire			is_x_in_range_4	=	(col_cnt	>=	3*TILE_WIDTH);

wire			is_y_in_range_1	=	(row_cnt	<	TILE_HEIGHT	);
wire			is_y_in_range_2	=	(row_cnt	>=	1*TILE_HEIGHT)&&(row_cnt	<	2*TILE_HEIGHT);
wire			is_y_in_range_3	=	(row_cnt	>=	2*TILE_HEIGHT)&&(row_cnt	<	3*TILE_HEIGHT);
wire			is_y_in_range_4	=	(row_cnt	>=	3*TILE_HEIGHT);

reg			[7:0]	r1,g1,b1;
always @(posedge clk)
		{r1,	g1,		b1	}		<=	{r0,	g0,		b0	};
								//2 clk
reg		[1:0]	x_tile_label;
reg		[1:0]	y_tile_label;
always @(posedge clk) begin
	case({is_x_in_range_4,is_x_in_range_3,is_x_in_range_2,is_x_in_range_1})
		4'b0001:
			x_tile_label	<=	2'b00;
		4'b0010:
			x_tile_label	<=	2'b01;
		4'b0100:
			x_tile_label	<=	2'b10;
		4'b1000:
			x_tile_label	<=	2'b11;
	endcase
	
	case({is_y_in_range_4,is_y_in_range_3,is_y_in_range_2,is_y_in_range_1})
		4'b0001:
			y_tile_label	<=	2'b00;
		4'b0010:
			y_tile_label	<=	2'b01;
		4'b0100:
			y_tile_label	<=	2'b10;
		4'b1000:
			y_tile_label	<=	2'b11;
	endcase
end
	

								//根据pixel 的位置生成相应的地址
reg		[11:0]	gamma_r0_addr_m,gamma_g0_addr_m,gamma_b0_addr_m;
always @(*)
	gamma_r0_addr_m		=	(gammaSet_en)	?	gamma_addr:{y_tile_label,x_tile_label,r1};
always @(*)
	gamma_g0_addr_m		=	(gammaSet_en)	?	gamma_addr:{y_tile_label,x_tile_label,g1};
always @(*)
	gamma_b0_addr_m		=	(gammaSet_en)	?	gamma_addr:{y_tile_label,x_tile_label,b1};

								//right tile地址生成器
wire	[1:0]	cc0		=	{x_tile_label+1};
wire	[1:0]	cc1		=	{y_tile_label+1};
reg		[11:0]	gamma_r0_addr_r,gamma_g0_addr_r,gamma_b0_addr_r;
always @(*)
	gamma_r0_addr_r		=	(gammaSet_en)	?	gamma_addr:{y_tile_label,cc0,r1};					
always @(*)
	gamma_g0_addr_r		=	(gammaSet_en)	?	gamma_addr:{y_tile_label,cc0,g1};
always @(*)
	gamma_b0_addr_r		=	(gammaSet_en)	?	gamma_addr:{y_tile_label,cc0,b1};

reg		[11:0]	gamma_r0_addr_u,gamma_g0_addr_u,gamma_b0_addr_u;
always @(*)
	gamma_r0_addr_u		=	(gammaSet_en)	?	gamma_addr:{y_tile_label	+1,x_tile_label,r1};
always @(*)
	gamma_g0_addr_u		=	(gammaSet_en)	?	gamma_addr:{y_tile_label	+1,x_tile_label,g1};
always @(*)
	gamma_b0_addr_u		=	(gammaSet_en)	?	gamma_addr:{y_tile_label	+1,x_tile_label,b1};
	
reg		[11:0]	gamma_r0_addr_o,gamma_g0_addr_o,gamma_b0_addr_o;
always @(*)
	gamma_r0_addr_o		=	(gammaSet_en)	?	gamma_addr:{cc1,cc0,r1};
always @(*)
	gamma_g0_addr_o		=	(gammaSet_en)	?	gamma_addr:{cc1,cc0,g1};
always @(*)
	gamma_b0_addr_o		=	(gammaSet_en)	?	gamma_addr:{cc1,cc0,b1};
								//构造块查找表	R	G	B
								//根据pixel 的位置生成相应的临近块地址
wire	[7:0]			r0_m;
wire	[7:0]			g0_m;
wire	[7:0]			b0_m;

gamma_lutx4K u_gamma_r_lut0
(
	.doa			(r0_m			),
	.dia			(gamma_wdata	),
								//3clk
	
	.addra			(gamma_r0_addr_m), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b00)
									) 
);
gamma_lutx4K u_gamma_g_lut0
(
	.doa			(g0_m			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_g0_addr_m), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b01)
									)
);
gamma_lutx4K u_gamma_b_lut0
(
	.doa			(b0_m			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_b0_addr_m), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b10)
									)
);
wire	[7:0]			r0_r;
wire	[7:0]			g0_r;
wire	[7:0]			b0_r;
								//M1_1查找表
gamma_lutx4K u_gamma_r_lut1
(
	.doa			(r0_r			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_r0_addr_r), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b00)
									)
);
gamma_lutx4K u_gamma_g_lut1
(
	.doa			(g0_r			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_g0_addr_r), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b01)
									)
);
gamma_lutx4K u_gamma_b_lut1
(
	.doa			(b0_r			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_b0_addr_r), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b10)
									)
);
wire	[7:0]			r0_u;
wire	[7:0]			g0_u;
wire	[7:0]			b0_u;
								//M1_2查找表
gamma_lutx4K u_gamma_r_lut2
(
	.doa			(r0_u			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_r0_addr_u), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b00)
									) 
);
gamma_lutx4K u_gamma_g_lut2
(
	.doa			(g0_u			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_g0_addr_u), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b01)
									) 
);
gamma_lutx4K u_gamma_b_lut2
(
	.doa			(b0_u			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_b0_addr_u), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b10)
									) 
);

wire	[7:0]			r0_o;
wire	[7:0]			g0_o;
wire	[7:0]			b0_o;
								//M2_2查找表
gamma_lutx4K u_gamma_r_lut3
(
	.doa			(r0_o			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_r0_addr_o), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b00)
									) 
);
gamma_lutx4K u_gamma_g_lut3
(
	.doa			(g0_o			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_g0_addr_o), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b01)
									) 
);
gamma_lutx4K u_gamma_b_lut3
(
	.doa			(b0_o			),
	.dia			(gamma_wdata	),
	
	.addra			(gamma_b0_addr_o), 
	.cea			(1'b1			), 
	
	.clka			(clk			), 
	.wea			(gammaSet_en	
					&&(gammaTable_sel ==2'b10)
									) 
);
								//花费 36K 空间构造查找表
								//装载除法量化表
reg		[7:0]		y_Q_lut	[0:255];
reg		[7:0]		x_Q_lut	[0:255];								
								//接下来做双线性插值处理	--Bilinear
								//第一步计算pixel 		在tile中相对位置
reg		[7:0]		pixel_y_rel_q0;
reg		[7:0]		pixel_x_rel_q0;
reg		[7:0]		pixel_y_rel_p0;
reg		[7:0]		pixel_x_rel_p0;

reg		[7:0]		pixel_y_rel;
reg		[7:0]		pixel_x_rel;

wire	[7:0]		pixel_x_mod;
wire	[7:0]		pixel_y_mod;
always @(posedge clk)
	pixel_x_rel_q0		<=x_Q_lut[col_cnt	%	TILE_WIDTH	];
								//2 clk
always @(posedge clk)
	pixel_y_rel_q0		<=y_Q_lut[row_cnt	%	TILE_HEIGHT	];
always @(posedge clk)
	pixel_x_rel_p0		<=pixel_x_rel_q0;
								//1 clk
always @(posedge clk)
	pixel_y_rel_p0		<=pixel_y_rel_q0;

always @(posedge clk)
	pixel_x_rel			<=pixel_x_rel_p0;
								//2 clk
always @(posedge clk)
	pixel_y_rel			<=pixel_y_rel_p0;
	
initial begin
	$readmemh	(FILENAME_YQ, y_Q_lut,	0,255		);
	$readmemh	(FILENAME_XQ, x_Q_lut,	0,255		);
end

assign				pixel_x_mod		=	255	-pixel_x_rel;
assign				pixel_y_mod		=	255	-pixel_y_rel;
								//进行插值操作
								//上插值	(R channel)
wire	[17:0]		red_ro_mul;
wire	[17:0]		red_or_mul;
wire	[17:0]		red_um_mul;
wire	[17:0]		red_mu_mul;
								//花费 2 DSP

wire	[17:0]		green_ro_mul;
wire	[17:0]		green_or_mul;
wire	[17:0]		green_um_mul;
wire	[17:0]		green_mu_mul;
								//花费 2 DSP

wire	[17:0]		blue_ro_mul;
wire	[17:0]		blue_or_mul;
wire	[17:0]		blue_um_mul;
wire	[17:0]		blue_mu_mul;
								//花费 2 DSP		--	6 DSP


								//先做两个Y方向插值	
								//右插值			0
dsp_x9_unsigned u_dsp_x9_R_ro(
	.p			(red_ro_mul		),
	.a			({1'b0,pixel_y_mod				
								}),
	.b			({1'b0,r0_r
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9_unsigned u_dsp_x9_R_or(
	.p			(red_or_mul		),
	.a			({1'b0,pixel_y_rel			
								}),
	.b			({1'b0,r0_o
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
								//左插值			0
dsp_x9_unsigned u_dsp_x9_R_mu(
	.p			(red_mu_mul		),
	.a			({1'b0,pixel_y_mod				
								}),
	.b			({1'b0,r0_m
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9_unsigned u_dsp_x9_R_um(
	.p			(red_um_mul		),
	.a			({1'b0,pixel_y_rel			
								}),
	.b			({1'b0,r0_u
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);


								//绿色通道插值算法
dsp_x9_unsigned u_dsp_x9_G_ro(
	.p			(green_ro_mul	),
	.a			({1'b0,pixel_y_mod				
								}),
	.b			({1'b0,g0_r
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9_unsigned u_dsp_x9_G_or(
	.p			(green_or_mul	),
	.a			({1'b0,pixel_y_rel			
								}),
	.b			({1'b0,g0_o
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
								//左插值			0
dsp_x9_unsigned u_dsp_x9_G_mu(
	.p			(green_mu_mul	),
	.a			({1'b0,pixel_y_mod				
								}),
	.b			({1'b0,g0_m
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9_unsigned u_dsp_x9_G_um(
	.p			(green_um_mul	),
	.a			({1'b0,pixel_y_rel			
								}),
	.b			({1'b0,g0_u
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);

								//蓝色通道插值算法
dsp_x9_unsigned u_dsp_x9_B_ro(
	.p			(blue_ro_mul	),
	.a			({1'b0,pixel_y_mod				
								}),
	.b			({1'b0,b0_r
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9_unsigned u_dsp_x9_B_or(
	.p			(blue_or_mul	),
	.a			({1'b0,pixel_y_rel			
								}),
	.b			({1'b0,b0_o
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
								//左插值			0
dsp_x9_unsigned u_dsp_x9_B_mu(
	.p			(blue_mu_mul	),
	.a			({1'b0,pixel_y_mod				
								}),
	.b			({1'b0,b0_m
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
dsp_x9_unsigned u_dsp_x9_B_um(
	.p			(blue_um_mul	),
	.a			({1'b0,pixel_y_rel			
								}),
	.b			({1'b0,b0_u
							}	), 
	.cea		(syn_d[1]		), 
	.ceb		(syn_d[1]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
								//一次插值结束


reg		[7:0]	o_r0,o_g0,o_b0;
								//注意pixel_y_rel 与addr 同时建立需要延时一个周期等待 r0_x建立
reg		[7:0]		pixel_y_rel_q1;
reg		[7:0]		pixel_x_rel_q1;

reg		[7:0]		pixel_y_mod_q1;
reg		[7:0]		pixel_x_mod_q1;
always @(posedge clk)
	pixel_y_rel_q1	<=pixel_y_rel;
always @(posedge clk)
	pixel_x_rel_q1	<=pixel_x_rel;

always @(posedge clk)
	pixel_y_mod_q1	<=pixel_y_mod;
always @(posedge clk)
	pixel_x_mod_q1	<=pixel_x_mod;
								//差值算法	(略)	--	左右线性插值	--上下线性插值
wire	[18:0]		ss_r_00	=	red_mu_mul +red_um_mul;
wire	[18:0]		ss_r_01	=	red_ro_mul +red_or_mul;

wire	[18:0]		ss_g_00	=	green_mu_mul +green_um_mul;
wire	[18:0]		ss_g_01	=	green_ro_mul +green_or_mul;

wire	[18:0]		ss_b_00	=	blue_mu_mul +blue_um_mul;
wire	[18:0]		ss_b_01	=	blue_ro_mul +blue_or_mul;
								//得到第一次Y方向插值,接下来进行x方向插值
								//总共花费 3 DSP	Totally	-->	9DSPs
wire	[17:0]		red_f_mul_x0;
wire	[17:0]		red_f_mul_x1;
dsp_x9_unsigned u_dsp_x9_R_xx0(
	.p			(red_f_mul_x0	),
	.a			({1'b0,pixel_x_mod_q1			
								}),
	.b			({1'b0,ss_r_00[15:8]
							}	), 
	.cea		(syn_d[4]		), 
	.ceb		(syn_d[4]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);

dsp_x9_unsigned u_dsp_x9_R_xx1(
	.p			(red_f_mul_x1	),
	.a			({1'b0,pixel_x_rel_q1			
								}),
	.b			({1'b0,ss_r_01[15:8]
							}	), 
	.cea		(syn_d[4]		), 
	.ceb		(syn_d[4]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
wire	[18:0]	sm_r=	red_f_mul_x0 +red_f_mul_x1;

wire	[17:0]		green_f_mul_x0;
wire	[17:0]		green_f_mul_x1;
dsp_x9_unsigned u_dsp_x9_G_xx0(
	.p			(green_f_mul_x0	),
	.a			({1'b0,pixel_x_mod_q1			
								}),
	.b			({1'b0,ss_g_00[15:8]
							}	), 
	.cea		(syn_d[4]		), 
	.ceb		(syn_d[4]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);

dsp_x9_unsigned u_dsp_x9_G_xx1(
	.p			(green_f_mul_x1	),
	.a			({1'b0,pixel_x_rel_q1			
								}),
	.b			({1'b0,ss_g_01[15:8]
							}	), 
	.cea		(syn_d[4]		), 
	.ceb		(syn_d[4]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
wire	[18:0]	sm_g=	green_f_mul_x0 +green_f_mul_x1;

wire	[17:0]		blue_f_mul_x0;
wire	[17:0]		blue_f_mul_x1;
dsp_x9_unsigned u_dsp_x9_B_xx0(
	.p			(blue_f_mul_x0	),
	.a			({1'b0,pixel_x_mod_q1			
								}),
	.b			({1'b0,ss_b_00[15:8]
							}	), 
	.cea		(syn_d[4]		), 
	.ceb		(syn_d[4]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);

dsp_x9_unsigned u_dsp_x9_B_xx1(
	.p			(blue_f_mul_x1	),
	.a			({1'b0,pixel_x_rel_q1			
								}),
	.b			({1'b0,ss_b_01[15:8]
							}	), 
	.cea		(syn_d[4]		), 
	.ceb		(syn_d[4]		), 
	
	.cepd		(1'b1			),
	
	.clk		(clk			), 
	.rstan		(reset_n		), 
	.rstbn		(reset_n		), 
	.rstpdn		(reset_n		) 
);
wire	[18:0]	sm_b=	blue_f_mul_x0 +blue_f_mul_x1;

always @(posedge clk)
	begin
		o_r0		<=	sm_r[15:8];
		o_g0		<=	sm_g[15:8];
		o_b0		<=	sm_b[15:8];
	end
/*
always @(posedge clk)
	o_r0						<=	sm_r_00[16:9];
always @(posedge clk)
	o_g0						<=	sm_g_00[16:9];
always @(posedge clk)
	o_b0						<=	sm_b_00[16:9];
*/
assign			o_data			=	{o_r0,	o_g0	,o_b0		};
assign			o_video_sync	=	{syn_v[8],syn_d[8],syn_h[8]	};
endmodule	