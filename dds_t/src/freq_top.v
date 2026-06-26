// =====================================================================
//  freq_top : 测 ad_data 频率/占空比 + seg_driver 显示
//  mode_1=0 → 显示频率 (XXX.X Hz)
//  mode_1=1 → 显示占空比 (XX.X %)
// =====================================================================
module freq_top(
    input  wire        clk,        // 12MHz (PIN_23)
    input  wire        rst_n,      // 复位, 低有效
    input  wire [7:0]  ad_data,    // ADC 采样数据(无符号, 中点≈128)
    input  wire        mode_1,     // 显示切换: 0=频率, 1=占空比 (PIN_59)
    output wire [7:0]  seg,        // 段选(1点亮) -> 接 seg[7..0] 引脚
    output wire [7:0]  sel         // 位选(1选中) -> 接 dig[7..0] 引脚
);
    wire [31:0] freq_x10;
    wire [31:0] duty_x10;
    wire [31:0] disp_value = mode_1 ? duty_x10 : freq_x10;

    freq_meter u_meter (
        .clk     (clk),
        .rst_n   (rst_n),
        .ad_data (ad_data),
        .freq_x10(freq_x10),
        .duty_x10(duty_x10)
    );

    seg_driver u_disp (
        .sys_clk (clk),
        .freq_x10(disp_value),
        .seg     (seg),
        .sel     (sel)
    );
endmodule


// ---------------------------------------------------------------------
//  freq_meter : 1 秒闸门直接计数测频 + 占空比测量
//  对 ad_data 做带迟滞的过中点检测
//  freq_x10 = 频率×10, duty_x10 = 占空比×10 (0~1000 = 0.0%~100.0%)
// ---------------------------------------------------------------------
module freq_meter #(
    parameter [23:0] GATE_MAX = 24'd11_999_999, // 1s @12MHz, 分辨率 1Hz
    parameter [7:0]  THR_HI   = 8'd140,         // 迟滞上门限
    parameter [7:0]  THR_LO   = 8'd116          // 迟滞下门限
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  ad_data,
    output reg  [31:0] freq_x10,
    output reg  [31:0] duty_x10
);
    // 1. 带迟滞过中点检测 + 上升沿(一个上升沿 = 一个信号周期)
    reg level, level_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)                 level <= 1'b0;
        else if (ad_data >= THR_HI) level <= 1'b1;
        else if (ad_data <= THR_LO) level <= 1'b0;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) level_d <= 1'b0;
        else        level_d <= level;
    end
    wire rise = level & ~level_d;
    wire fall = ~level & level_d;

    // 2. 1 秒闸门
    reg [23:0] gate_cnt;
    wire gate_end = (gate_cnt == GATE_MAX);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)        gate_cnt <= 24'd0;
        else if (gate_end) gate_cnt <= 24'd0;
        else               gate_cnt <= gate_cnt + 1'b1;
    end

    // 3. 计数 + 闸门结束锁存(频率×10)
    reg [27:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt      <= 28'd0;
            freq_x10 <= 32'd0;
        end else if (gate_end) begin
            if (cnt != 0 || rise)  // 有信号才更新，无信号保持上次值
                freq_x10 <= (rise ? (cnt + 1'b1) : cnt) * 28'd10;
            cnt      <= 28'd0;
        end else if (rise) begin
            cnt <= cnt + 1'b1;
        end
    end

    // 4. 占空比: 脉冲矩形法 — 逐周期测高宽度/(高+低), 64次平均
    //    只统计完整脉冲 (上升沿→下降沿→上升沿), 剔除闸门边界不完整脉冲
    reg [23:0] dc_hcnt;       // 当前脉冲高电平时钟数
    reg [23:0] dc_pcnt;       // 当前脉冲周期时钟数
    reg [31:0] dc_hsum;       // 累加高宽度
    reg [31:0] dc_psum;       // 累加周期
    reg [5:0]  dc_ncnt;       // 已累加脉冲数 (0~63)
    reg        dc_high;       // 1=正在测高电平, 0=正在测低电平
    reg        dc_run;        // 1=已捕获到首上升沿, 开始测量

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dc_run <= 1'b0; dc_high <= 1'b0;
            dc_hcnt <= 24'd0; dc_pcnt <= 24'd0;
            dc_hsum <= 32'd0; dc_psum <= 32'd0;
            dc_ncnt <= 6'd0;
            duty_x10 <= 32'd0;
        end else if (gate_end) begin
            // 闸门结束: 用已完成脉冲算平均, 丢弃当前不完整脉冲
            if (dc_ncnt != 0) begin
                duty_x10 <= (dc_hsum * 32'd1000) / dc_psum;
            end
            dc_run <= 1'b0;
            dc_hsum <= 32'd0; dc_psum <= 32'd0; dc_ncnt <= 6'd0;
            dc_hcnt <= 24'd0; dc_pcnt <= 24'd0;
        end else begin
            // 两个计数器一直跑
            if (dc_run) dc_pcnt <= dc_pcnt + 1'b1;
            if (dc_run && dc_high) dc_hcnt <= dc_hcnt + 1'b1;

            if (rise) begin
                if (!dc_run) begin
                    // 首个上升沿, 启动测量
                    dc_run <= 1'b1; dc_high <= 1'b1;
                    dc_hcnt <= 24'd0; dc_pcnt <= 24'd0;
                end else begin
                    // 完整周期结束, 加入累加器
                    if (dc_ncnt == 6'd63) begin
                        // 够64个脉冲 → 算平均, 重置累加器
                        duty_x10 <= ((dc_hsum + dc_hcnt) * 32'd1000)
                                  / (dc_psum + dc_pcnt);
                        dc_hsum <= 32'd0; dc_psum <= 32'd0;
                        dc_ncnt <= 6'd0;
                    end else begin
                        dc_hsum <= dc_hsum + dc_hcnt;
                        dc_psum <= dc_psum + dc_pcnt;
                        dc_ncnt <= dc_ncnt + 1'b1;
                    end
                    // 重置脉冲计数器, 继续测下一个周期
                    dc_hcnt <= 24'd0; dc_pcnt <= 24'd0;
                    dc_high <= 1'b1;
                end
            end else if (fall && dc_run && dc_high) begin
                // 高电平结束, 切到低电平 (dc_pcnt继续累加)
                dc_high <= 1'b0;
            end
        end
    end
endmodule
