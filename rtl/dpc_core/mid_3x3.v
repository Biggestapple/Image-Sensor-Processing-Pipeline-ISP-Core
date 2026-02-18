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
//	FILE: 		mid_3x3.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple 		2024.4.8		Create									#00
//----------------------------------------------------------------------------------------------------------
module mid_3x3(
	input			clk,
	input			reset_n,
	
	input			i_line_vaild,
	output			o_data_valid,
								//输入8位无符号数
	input	[23:0]	i_line3_1,
	input	[23:0]	i_line3_2,
	input	[23:0]	i_line3_3,
								//快速中值法的实现
	output	[7:0]	o_mid_data
);
reg		data_vaild;
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		data_vaild	<=	1'b0;
	else
		data_vaild	<=	i_line_vaild;

reg		[7:0]	r1_1_d,r1_2_d,r1_3_d;
reg		[7:0]	r2_1_d,r2_2_d,r2_3_d;
reg		[7:0]	r3_1_d,r3_2_d,r3_3_d;
always @(*) begin
	{r1_1_d,r1_2_d,r1_3_d}		=i_line3_1;
	{r2_1_d,r2_2_d,r2_3_d}		=i_line3_2;
	{r3_1_d,r3_2_d,r3_3_d}		=i_line3_3;
end

reg		[7:0]	r1_1,r1_2,r1_3;
reg		[7:0]	r2_1,r2_2,r2_3;
reg		[7:0]	r3_1,r3_2,r3_3;

reg		[7:0]	r1_max,r1_mid,r1_min;
reg		[7:0]	r2_max,r2_mid,r2_min;
reg		[7:0]	r3_max,r3_mid,r3_min;

always @(posedge clk)
	{r1_1,r1_2,r1_3	}	<=	{i_line3_1};
always @(posedge clk)
	{r2_1,r2_2,r2_3	}	<=	{i_line3_2};
always @(posedge clk)
	{r3_1,r3_2,r3_3	}	<=	{i_line3_3};
								//锁定一个周期

wire	a_cmp1_12,a_cmp1_13,a_cmp1_23;
wire	a_cmp2_12,a_cmp2_13,a_cmp2_23;
wire	a_cmp3_12,a_cmp3_13,a_cmp3_23;

assign	a_cmp1_12	=	~(r1_1_d	>r1_2_d);
assign	a_cmp1_13	=	~(r1_1_d	>r1_3_d);
assign	a_cmp1_23	=	~(r1_2_d	>r1_3_d);

assign	a_cmp2_12	=	~(r2_1_d	>r2_2_d);
assign	a_cmp2_13	=	~(r2_1_d	>r2_3_d);
assign	a_cmp2_23	=	~(r2_2_d	>r2_3_d);

assign	a_cmp3_12	=	~(r3_1_d	>r3_2_d);
assign	a_cmp3_13	=	~(r3_1_d	>r3_3_d);
assign	a_cmp3_23	=	~(r3_2_d	>r3_3_d);
always @(posedge clk) begin
								//进行第一次排序,耗费一个 clk
								//排列第一行
		case({a_cmp1_12,a_cmp1_13,a_cmp1_23})
			3'b000:	{r1_max,r1_mid,r1_min}	<=	{r1_1_d,r1_2_d,r1_3_d};
			3'b001:	{r1_max,r1_mid,r1_min}	<=	{r1_1_d,r1_3_d,r1_2_d};
			3'b011:	{r1_max,r1_mid,r1_min}	<=	{r1_3_d,r1_1_d,r1_2_d};
			3'b100:	{r1_max,r1_mid,r1_min}	<=	{r1_2_d,r1_1_d,r1_3_d};
			3'b110:	{r1_max,r1_mid,r1_min}	<=	{r1_2_d,r1_3_d,r1_1_d};
			3'b111:	{r1_max,r1_mid,r1_min}	<=	{r1_3_d,r1_2_d,r1_1_d};
			default:
					{r1_max,r1_mid,r1_min}	<=	0	;
		endcase
								//排列第二行
		case({a_cmp2_12,a_cmp2_13,a_cmp2_23})
			3'b000:	{r2_max,r2_mid,r2_min}	<=	{r2_1_d,r2_2_d,r2_3_d};
			3'b001:	{r2_max,r2_mid,r2_min}	<=	{r2_1_d,r2_3_d,r2_2_d};
			3'b011:	{r2_max,r2_mid,r2_min}	<=	{r2_3_d,r2_1_d,r2_2_d};
			3'b100:	{r2_max,r2_mid,r2_min}	<=	{r2_2_d,r2_1_d,r2_3_d};
			3'b110:	{r2_max,r2_mid,r2_min}	<=	{r2_2_d,r2_3_d,r2_1_d};
			3'b111:	{r2_max,r2_mid,r2_min}	<=	{r2_3_d,r2_2_d,r2_1_d};
			default:
					{r2_max,r2_mid,r2_min}	<=	0	;
		endcase
								//排列第三行
		case({a_cmp3_12,a_cmp3_13,a_cmp3_23})
			3'b000:	{r3_max,r3_mid,r3_min}	<=	{r3_1_d,r3_2_d,r3_3_d};
			3'b001:	{r3_max,r3_mid,r3_min}	<=	{r3_1_d,r3_3_d,r3_2_d};
			3'b011:	{r3_max,r3_mid,r3_min}	<=	{r3_3_d,r3_1_d,r3_2_d};
			3'b100:	{r3_max,r3_mid,r3_min}	<=	{r3_2_d,r3_1_d,r3_3_d};
			3'b110:	{r3_max,r3_mid,r3_min}	<=	{r3_2_d,r3_3_d,r3_1_d};
			3'b111:	{r3_max,r3_mid,r3_min}	<=	{r3_3_d,r3_2_d,r3_1_d};
			default:
					{r3_max,r3_mid,r3_min}	<=	0	;
		endcase
	end
reg		[7:0]	b1_max,b1_mid,b1_min;
reg		[7:0]	b2_max,b2_mid,b2_min;
reg		[7:0]	b3_max,b3_mid,b3_min;
								//第二次排序,对各个行的最大最小值进行排序
								//花费一个 clk
wire	b_cmp1_12,b_cmp1_13,b_cmp1_23;
								//Max 排序
wire	b_cmp2_12,b_cmp2_13,b_cmp2_23;
								//Mid 排序
wire	b_cmp3_12,b_cmp3_13,b_cmp3_23;
								//Min 排序

assign	b_cmp1_12	=	~(r1_max	>r2_max);
assign	b_cmp1_13	=	~(r1_max	>r3_max);
assign	b_cmp1_23	=	~(r2_max	>r3_max);

assign	b_cmp2_12	=	~(r1_mid	>r2_mid);
assign	b_cmp2_13	=	~(r1_mid	>r3_mid);
assign	b_cmp2_23	=	~(r2_mid	>r3_mid);

assign	b_cmp3_12	=	~(r1_min	>r2_min);
assign	b_cmp3_13	=	~(r1_min	>r3_min);
assign	b_cmp3_23	=	~(r2_min	>r3_min);
always @(posedge clk) begin
								//进行第一次排序,耗费一个 clk
								//排列第一行
		case({b_cmp1_12,b_cmp1_13,b_cmp1_23})
			3'b000:	{b1_max,b1_mid,b1_min}	<=	{r1_max,r2_max,r3_max};
			3'b001:	{b1_max,b1_mid,b1_min}	<=	{r1_max,r3_max,r2_max};
			3'b011:	{b1_max,b1_mid,b1_min}	<=	{r3_max,r1_max,r2_max};
			3'b100:	{b1_max,b1_mid,b1_min}	<=	{r2_max,r1_max,r3_max};
			3'b110:	{b1_max,b1_mid,b1_min}	<=	{r2_max,r3_max,r1_max};
			3'b111:	{b1_max,b1_mid,b1_min}	<=	{r3_max,r2_max,r1_max};
			default:
					{b1_max,b1_mid,b1_min}	<=	0	;
		endcase
								//排列第二行
		case({b_cmp2_12,b_cmp2_13,b_cmp2_23})
			3'b000:	{b2_max,b2_mid,b2_min}	<=	{r1_mid,r2_mid,r3_mid};
			3'b001:	{b2_max,b2_mid,b2_min}	<=	{r1_mid,r3_mid,r2_mid};
			3'b011:	{b2_max,b2_mid,b2_min}	<=	{r3_mid,r1_mid,r2_mid};
			3'b100:	{b2_max,b2_mid,b2_min}	<=	{r2_mid,r1_mid,r3_mid};
			3'b110:	{b2_max,b2_mid,b2_min}	<=	{r2_mid,r3_mid,r1_mid};
			3'b111:	{b2_max,b2_mid,b2_min}	<=	{r3_mid,r2_mid,r1_mid};
			default:
					{b2_max,b2_mid,b2_min}	<=	0	;
		endcase
								//排列第三行
		case({b_cmp3_12,b_cmp3_13,b_cmp3_23})
			3'b000:	{b3_max,b3_mid,b3_min}	<=	{r1_min,r2_min,r3_min};
			3'b001:	{b3_max,b3_mid,b3_min}	<=	{r1_min,r3_min,r2_min};
			3'b011:	{b3_max,b3_mid,b3_min}	<=	{r3_min,r1_min,r2_min};
			3'b100:	{b3_max,b3_mid,b3_min}	<=	{r2_min,r1_min,r3_min};
			3'b110:	{b3_max,b3_mid,b3_min}	<=	{r2_min,r3_min,r1_min};
			3'b111:	{b3_max,b3_mid,b3_min}	<=	{r3_min,r2_min,r1_min};
			default:
					{b3_max,b3_mid,b3_min}	<=	0	;
		endcase
	end
								//进行最后一次排序,耗费一个 clk
reg		[7:0]	c1_max,c1_mid,c1_min;

wire	c_cmp1_12,c_cmp1_13,c_cmp1_23;
								//对最大值中最小值,中间值中中间值,最小值中最大值进行排序
assign	c_cmp1_12	=	~(b1_min	>b2_mid);
assign	c_cmp1_13	=	~(b1_min	>b3_max);
assign	c_cmp1_23	=	~(b2_mid	>b3_max);

always @(posedge clk) begin
		case({c_cmp1_12,c_cmp1_13,c_cmp1_23})
			3'b000:	{c1_max,c1_mid,c1_min}	<=	{b1_min,b2_mid,b3_max};
			3'b001:	{c1_max,c1_mid,c1_min}	<=	{b1_min,b3_max,b2_mid};
			3'b011:	{c1_max,c1_mid,c1_min}	<=	{b3_max,b1_min,b2_mid};
			3'b100:	{c1_max,c1_mid,c1_min}	<=	{b2_mid,b1_min,b3_max};
			3'b110:	{c1_max,c1_mid,c1_min}	<=	{b2_mid,b3_max,b1_min};
			3'b111:	{c1_max,c1_mid,c1_min}	<=	{b3_max,b2_mid,b1_min};
			default:
					{c1_max,c1_mid,c1_min}	<=	0	;
		endcase
end
reg	[2:0]	data_vaild_r;
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		data_vaild_r	<=	3'b000;
								//Noops... ...
	else
		data_vaild_r	<=	{data_vaild_r[1:0],i_line_vaild};
								//最终输出矩阵中值
assign	o_mid_data	=	c1_mid										;
								//花费	3 clks
assign	o_data_valid=	data_vaild_r[2]								;
endmodule