module segmentD(
    input clk,
	input rst,
    input wire [27:0] num, 
    input sel_out,
    
    output reg dp,
    output reg [7:0] seg_code, //显示的数字
	output reg [7:0] digit_sel
);

reg [13:0] div_cnt;  //分频器
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        div_cnt <= 14'd0;
    end else if (div_cnt == 14'd2999) begin 
        div_cnt <= 14'd0;
    end else begin
        div_cnt <= div_cnt + 14'd1;
    end
end

reg [2:0] scan_cnt; //扫描计数器
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        scan_cnt <= 3'd0;
    end else if (scan_cnt == 3'd6) begin  
        scan_cnt <= 3'd0;
    end
     else if (div_cnt == 14'd2999) begin  
        scan_cnt <= scan_cnt + 3'd1;
    end
end

always @(*) begin //使能
    case (scan_cnt)
        3'd0: digit_sel = 8'b00000001;
        3'd1: digit_sel = 8'b00000010; 
        3'd2: digit_sel = 8'b00000100; 
        3'd3: digit_sel = 8'b00001000; 
        3'd4: digit_sel = 8'b00010000; 
        3'd5: digit_sel = 8'b00100000; 
        3'd6: digit_sel = 8'b01000000; 
        3'd7: digit_sel = 8'b10000000; 
        default: digit_sel = 8'b00000000;
    endcase
end

reg [3:0] curr_num; 
always @(*) begin
    case (scan_cnt)
        3'd0: curr_num = num[3:0];   
        3'd1: curr_num = num[7:4]; 
        3'd2: curr_num = num[11:8];  
        3'd3: curr_num = num[15:12]; 
        3'd4: curr_num = num[19:16]; 
        3'd5: curr_num = num[23:20]; 
        3'd6: curr_num = num[27:24]; 
        
        default: curr_num = 4'd0;
    endcase
end

always @(*) begin
    // sel_out = 1:显示的频率，curr_num 为1时是倒数第二个管
    if (sel_out == 1 && scan_cnt == 1) begin
        dp = 1'b1; // 显示时，点灯
        //seg_code |= 8'b1000_0000;
    end else begin
        dp = 1'b0; // 不显示时，灭
        //seg_code &= ~8'b1000_0000;
    end
end

always @(*) begin
    // 段码定义：seg_code[7:0] = {dp, g, f, e, d, c, b, a}
    // 共阴极：高电平(1)点亮，低电平(0)熄灭
    case (curr_num)
        4'd0: seg_code = 8'b0011_1111;  // 0：dp灭, g灭, a-f亮
        4'd1: seg_code = 8'b0000_0110;  // 1：b、c亮
        4'd2: seg_code = 8'b0101_1011;  // 2：a、b、g、e、d亮
        4'd3: seg_code = 8'b0100_1111;  // 3：a、b、g、c、d亮
        4'd4: seg_code = 8'b0110_0110;  // 4：f、g、b、c亮
        4'd5: seg_code = 8'b0110_1101;  // 5：a、f、g、c、d亮
        4'd6: seg_code = 8'b0111_1101;  // 6：a、f、g、c、d、e亮
        4'd7: seg_code = 8'b0000_0111;  // 7：a、b、c亮
        4'd8: seg_code = 8'b0111_1111;  // 8：全亮
        4'd9: seg_code = 8'b0110_1111;  // 9：a、b、c、d、f、g亮
        4'd10: seg_code = 0011_0111; //= 0x37
        4'd11: seg_code = 0111_1100; //= 0x7C
        4'd12: seg_code = 0011_1001; //= 0x39
        4'd13: seg_code = 0101_1110; //= 0x5E
        4'd14: seg_code = 0111_1001; //= 0x79
        4'd15: seg_code = 0111_0001; //= 0x71
        default: seg_code = 8'b00000000; // 默认全灭（高电平点亮则全0灭）
    endcase
end

endmodule

