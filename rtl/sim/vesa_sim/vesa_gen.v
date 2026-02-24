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
//	FILE: 		vesa_gen.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	Generate vesa-timing video flow	(bayer format)
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.8		Create
//----------------------------------------------------------------------------------------------------------
module vesa_gen#(
	parameter		FILENAME	=	"",
	parameter[15:0]	xres		=	640,
	parameter[15:0]	yres		=	480
)(
	input			clk,
	input			o_video_en,
	
	output	[2:0]	o_video_syn,
	
	output	[7:0]	o_data
);
wire	syn_d,syn_v,syn_h;
parameter			[15:0]			syn_h_back	=	16;
reg		[1:0]		o_video_en_r	=	0;
reg		[7:0]		video_buffer	[0:xres	*yres -1	];
								//读取视频流文件
initial begin
	$readmemh	(FILENAME, video_buffer, 0, xres	*yres -1	);
	$display	("File has been read successfully. Len:	%d	bytes.",xres	*yres -1);
end
always @(posedge clk)
	o_video_en_r	<=	{o_video_en_r[0],o_video_en};
wire	o_video_en_pos	=	o_video_en_r	==	2'b01;

reg		[15:0]			d_cnt	=	'd0;
reg		[15:0]			v_cnt	=	'd0;

always @(posedge clk) begin
	if(o_video_en_pos)
		d_cnt	<=	'd1;
	else if(d_cnt	!=	0 && d_cnt	!=syn_h_back +xres	-1)
		d_cnt	<=	d_cnt	+1;
	else if(d_cnt	==syn_h_back +xres	-1 &&	v_cnt	!=yres-1)
		d_cnt	<=	'd1;
	else
		d_cnt	<=	'd0;
end

always @(posedge clk) begin
	if(o_video_en_pos)
		v_cnt	<=	0;
	else if(d_cnt	==	syn_h_back +xres-1	&& v_cnt	!= yres -1)
		v_cnt	<=	v_cnt +1;
	else if( v_cnt	== yres	)
		v_cnt	<=	0;
	else
		v_cnt	<=	v_cnt;
end

reg		[31:0]			video_addr		=0;
always @(posedge clk)
	if		(syn_d			)
		video_addr		<=	video_addr	+1;
	else if	(syn_v			)
		video_addr		<=	0;
		
assign	syn_h			=	d_cnt	>syn_h_back	-1;
assign	syn_d			=	d_cnt	>syn_h_back	-1;
assign	syn_v			=	o_video_en_pos		;
assign	o_data			=	syn_d==1'b1	?	video_buffer[video_addr]	:'b0;
wire	[31:0]			dbg_r1_v4
						=	video_addr		;
assign	o_video_syn		=	{syn_v,	syn_d,	syn_h};
endmodule