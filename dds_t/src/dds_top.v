module dds_top#(
    parameter N = 21,   // 相位累加器位宽
    parameter M = 16    // 频率控制字位宽
)(
    input clk,//时钟
    input reset_n,//复位
    //input[M - 1 : 0] Fword,//频率控制字
    input[4 : 0] Fword_in,
    input ce,
    input[1:0] select,
    input sel_out,
    output dp,
    output  [9:0] wave_out,
    output  [7:0] seg_code,
    output  [7:0] digit_sel,
    output  dac_clk_out
);

wire [27:0] out_freq;
wire [7:0] Pword = 0;



dds #(
    .N(N),   // 给 N 赋值
    .M(M)    // 给 K 赋值
) u_dds(
	.clk(clk),//时钟
	.reset_n(reset_n),//复位
	.ce(ce),
	.Fword({Fword_in[4:2], 11'b0,Fword_in[1:0]}),//频率控制字
	.Pword(Pword),//相位控制字
	.wave_out(wave_out),
	.dac_clk_in(clk),
	.dac_clk(dac_clk_out),
	.out_freq(out_freq),
	.select(select),
	.sel_out(sel_out)
	);

segmentD u_segmentD(
    .clk(clk),
    .rst(reset_n),
    .num(out_freq),
    .seg_code(seg_code),
    .sel_out(sel_out),
    .dp(dp),
    .digit_sel(digit_sel)
);

endmodule