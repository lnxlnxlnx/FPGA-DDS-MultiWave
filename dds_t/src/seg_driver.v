module seg_driver(
    input sys_clk,           // 12MHz 系统时钟
    input [31:0] freq_x10,   // 输入的放大10倍的频率值
    output reg [7:0] seg,    // 段选：1点亮，0熄灭
    output reg [7:0] sel     // 位选：1选中，0不选
);

    // --- 第一部分：二进制转 BCD ---
    reg [31:0] bcd_data;
    integer i;
    always @(*) begin
        bcd_data = 0;
        for (i = 31; i >= 0; i = i - 1) begin
            if (bcd_data[3:0] >= 5)   bcd_data[3:0] = bcd_data[3:0] + 3;
            if (bcd_data[7:4] >= 5)   bcd_data[7:4] = bcd_data[7:4] + 3;
            if (bcd_data[11:8] >= 5)  bcd_data[11:8] = bcd_data[11:8] + 3;
            if (bcd_data[15:12] >= 5) bcd_data[15:12] = bcd_data[15:12] + 3;
            if (bcd_data[19:16] >= 5) bcd_data[19:16] = bcd_data[19:16] + 3;
            if (bcd_data[23:20] >= 5) bcd_data[23:20] = bcd_data[23:20] + 3;
            if (bcd_data[27:24] >= 5) bcd_data[27:24] = bcd_data[27:24] + 3;
            if (bcd_data[31:28] >= 5) bcd_data[31:28] = bcd_data[31:28] + 3;
            bcd_data = {bcd_data[30:0], freq_x10[i]};
        end
    end

    // --- 第二部分：提取数字与高位消隐 ---
    reg [12:0] scan_cnt;
    reg [2:0] digit_idx;
    reg [3:0] current_digit;
    reg dot_flag;
    reg enable_flag;

    always @(posedge sys_clk) begin
        if (scan_cnt == 13'd5999) begin // 0.5ms 切换一次
            scan_cnt <= 0;
            digit_idx <= digit_idx + 1'b1;
        end else begin
            scan_cnt <= scan_cnt + 1'b1;
        end
    end

    always @(*) begin
        enable_flag = 1'b1;
        dot_flag = 1'b0;

        case(digit_idx)
            3'd0: begin current_digit = bcd_data[3:0]; end
            3'd1: begin current_digit = bcd_data[7:4];   dot_flag = 1'b1; end // 个位强制点亮小数点
            3'd2: begin current_digit = bcd_data[11:8];  if (bcd_data[31:8] == 0)  enable_flag = 1'b0; end
            3'd3: begin current_digit = bcd_data[15:12]; if (bcd_data[31:12] == 0) enable_flag = 1'b0; end
            3'd4: begin current_digit = bcd_data[19:16]; if (bcd_data[31:16] == 0) enable_flag = 1'b0; end
            3'd5: begin current_digit = bcd_data[23:20]; if (bcd_data[31:20] == 0) enable_flag = 1'b0; end
            3'd6: begin current_digit = bcd_data[27:24]; if (bcd_data[31:24] == 0) enable_flag = 1'b0; end
            3'd7: begin current_digit = bcd_data[31:28]; if (bcd_data[31:28] == 0) enable_flag = 1'b0; end
        endcase
    end

    // --- 第三部分：字模译码 (1=点亮) ---
    reg [6:0] seg_raw;
    always @(*) begin
        case(current_digit)
            4'h0: seg_raw = 7'b0111111;
            4'h1: seg_raw = 7'b0000110;
            4'h2: seg_raw = 7'b1011011;
            4'h3: seg_raw = 7'b1001111;
            4'h4: seg_raw = 7'b1100110;
            4'h5: seg_raw = 7'b1101101;
            4'h6: seg_raw = 7'b1111101;
            4'h7: seg_raw = 7'b0000111;
            4'h8: seg_raw = 7'b1111111;
            4'h9: seg_raw = 7'b1101111;
            default: seg_raw = 7'b0000000;
        endcase
    end

    // --- 第四部分：4步安全扫描 (完美规避毛刺) ---
    always @(posedge sys_clk) begin
        if (scan_cnt == 13'd0) begin
            // 第1步：断电 (位选全部给 0)
            sel <= 8'b00000000;

        end else if (scan_cnt == 13'd1500) begin
            // 第2步：在断电安全的黑暗中，布置好段选数据
            if (enable_flag) begin
                seg <= {dot_flag, seg_raw}; // 1 点亮
            end else begin
                seg <= 8'b00000000;         // 0 熄灭
            end

        end else if (scan_cnt == 13'd3000) begin
            // 第3步：开启当前这一位的电源 (位选给 1)
            if (enable_flag) begin
                sel <= (8'b00000001 << digit_idx);
            end
        end
        // 第4步：保持，直到下一个循环断电
    end

endmodule
