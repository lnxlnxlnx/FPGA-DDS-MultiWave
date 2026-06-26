<<<<<<< HEAD
module dds(
    clk,        // 系统时钟：10MHz
    reset_n,    // 低电平复位
    Fword,      // 频率控制字：8位（仅8个引脚，兼顾范围和步进）
    ce,         // 输出使能：高电平有效（直接接高，无需引脚）
    sine,       // 正弦波输出：10位（接THS5651）
    square,     // 方波输出：10位（可选，实验可只接正弦）
    triangle,    // 三角波输出：10位（可选，实验可只接正弦）
    dac_clk
);

  parameter N = 21;
  input clk;
  input ce;
  input reset_n;
  input [N - 1:0] Fword;
  input [7:0] Pword;//Rom地址11位：横坐标最大为：2048
  input dac_clk_in;
  output [9:0] sine;
  //output [9:0] cosine;
  output [9:0] square;
  output [9:0] triangle;
  //output [19:0] p;
  output dac_clk;

  reg [N - 1:0] r_Fword;//频率 寄存器
=======
module dds
#(
    parameter N = 21,   // 相位累加器位宽
    parameter M = 16    // 频率控制字位宽
)
(
    clk,//时钟
    reset_n,//复位
    Fword,//频率控制字
    Pword,//相位控制字
    ce,
    //p,
    wave_out,
    //cosine,//数据输出
    select,
    dac_clk_in,
    dac_clk,
    out_freq,
    //out_fword,
    sel_out
  );
  //f_out = Fword × f_clk / (2^N)
  //频率除8位再乘上8位那还是2^N!!!

  //parameter N = 21;
  //parameter M = 16;
  input clk;
  input ce;
  input reset_n;
  input [M - 1:0] Fword;
  input [7:0] Pword;//Rom地址11位：横坐标最大为：2048
  input dac_clk_in;
  input [1:0]select;
  output reg [9:0] wave_out;
  wire [9:0] sine;
  //wire [9:0] cosine;
  wire [9:0] square;
  wire [9:0] triangle;
  wire [9:0] sawtooth;
  //output [19:0] p;
  input sel_out;
  output dac_clk;
  output reg [27:0] out_freq;
  wire [27:0] out_fword;

  reg [M - 1:0] r_Fword;//频率 寄存器
>>>>>>> 8ffdd3d04c4a3a4d7ff615ba9421b32d5ae56e9c
  reg [7:0] r_Pword;//相位 寄存器
  //wire [9:0] DA_Data;
  wire [9:0] DA_Data1;
  wire [9:0] DA_Data2;
  wire [9:0] DA_Data3;
  wire [9:0] DA_Data4;


  //reg [9:0] DA_Data_r;
  reg [9:0] DA_Data1_r;
  reg [9:0] DA_Data2_r;
  reg [9:0] DA_Data3_r;
  reg [9:0] DA_Data4_r;

  reg [N - 1:0] Fcnt;//累加器
<<<<<<< HEAD

  wire [7:0] rom_addr;
=======

  wire [7:0] rom_addr;
  // ========== select 控制波形选择 ==========
  always @(*) begin
      case(select)
          3'b000: wave_out = sine;      // 正弦波
          3'b001: wave_out = square;    // 方波
          3'b010: wave_out = triangle;  // 三角波
          3'b011: wave_out = sawtooth;
          default: wave_out = 10'd0;    // 其他 → 0
      endcase
  end

>>>>>>> 8ffdd3d04c4a3a4d7ff615ba9421b32d5ae56e9c
  assign sine =DA_Data1_r;
  //assign cosine =DA_Data_r;
  assign square =DA_Data2_r;
  assign triangle =DA_Data3_r;
  assign sawtooth =DA_Data4_r;
  //assign out_freq = sel_out ? r_Fword:(r_Fword * 32'd120000000) / 21'd2097152;
  //wire [31:0] freq_calc = r_Fword * 32'd120000000;
  //wire [31:0] freq_result = freq_calc / 21'd2097152;
  always @(*)begin
    case (sel_out)
      0:  out_freq = Fword;
      1:  out_freq = Fword * 91;
      default: out_freq = 0;
    endcase
  end
  //assign out_fword = r_Fword;

// 输出频率公式：f_out = Fword × 12MHz / 2^21
// 乘个10就有小数了
//assign out_freq = (r_Fword * 32'd120000000) / 21'd2097152;
  //	wire [19:0] p;
  always @(posedge clk)
  begin
    r_Fword <= Fword;
end

// 2. 20位相位累加器（核心：保留20位，保证分辨率和采样点）
// 累加逻辑：低8位加r_Fword，高12位自然进位，无需额外处理
always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
      Fcnt <= 0;
    else
        Fcnt <= Fcnt + {12'd0, r_Fword};  // 核心：8位→20位补0，拼接后累加
end

<<<<<<< HEAD
// 3. 8位ROM地址生成（取累加器高8位，匹配实验要求）
assign rom_addr = Fcnt[19:12];

// 4. 输出缓存+使能控制（完全不变）
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        DA_Data1_r <= 10'd0;
        DA_Data2_r <= 10'd0;
        DA_Data3_r <= 10'd0;
=======
  always @(posedge clk or negedge reset_n)
  begin
    if(!reset_n)
    begin
      //DA_Data_r<= 10'd0;
      DA_Data1_r<= 10'd0;
      DA_Data2_r<= 10'd0;
      DA_Data3_r<= 10'd0;
      DA_Data4_r<= 10'd0;
>>>>>>> 8ffdd3d04c4a3a4d7ff615ba9421b32d5ae56e9c
    end
    else
    case(ce)
      1'b1 :
      begin
        //DA_Data_r <= DA_Data;
        DA_Data1_r <= DA_Data1;
        DA_Data2_r <= DA_Data2;
        DA_Data3_r <= DA_Data3;
        DA_Data4_r <= DA_Data4;
      end
      1'b0 :
      begin
        //DA_Data_r<= 10'd0;
        DA_Data1_r<= 10'd0;
        DA_Data2_r<= 10'd0;
        DA_Data3_r<= 10'd0;
        DA_Data4_r<= 10'd0;
      end
      default :
      begin
        //DA_Data_r<= 10'd0;
        DA_Data1_r<= 10'd0;
        DA_Data2_r<= 10'd0;
        DA_Data3_r<= 10'd0;
        DA_Data4_r<= 10'd0;
      end
    endcase
  end


  assign rom_addr = Fcnt[N - 1:N - 1 - 7] + r_Pword;


  //rom rom(
  //.address(rom_addr),
  //.clock(clk),
  //.q(DA_Data)
  //	);

  rom_sin rom_sin(
            .address(rom_addr),
            .clock(clk),
            .q(DA_Data1)
          );

rom_squ rom_squ(
    .address(rom_addr),
    .clock(clk),
    .q(DA_Data2)
);

<<<<<<< HEAD
rom_tri rom_tri(
    .address(rom_addr),
    .clock(clk),
    .q(DA_Data3)
);
=======
  rom_tri rom_tri(
            .address(rom_addr),
            .clock(clk),
            .q(DA_Data3)
          );
  
  rom_saw rom_saw(
            .address(rom_addr),
            .clock(clk),
            .q(DA_Data4)
          );
  /*
  mult mult(
  	.clk(clk),
  	.rst(reset_n),
  	.x(DA_Data),
  	.y(DA_Data1),
  	.p(p)
  	);
  	
  */
  //assign p = 	DA_Data1*DA_Data;
  assign dac_clk = dac_clk_in;
>>>>>>> 8ffdd3d04c4a3a4d7ff615ba9421b32d5ae56e9c

assign dac_clk = clk;

endmodule