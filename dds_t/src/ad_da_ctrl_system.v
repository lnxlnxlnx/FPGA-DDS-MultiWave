module ad_da_ctrl_system(
    input  wire        clk,          // 12MHz 主时钟 (原引脚 PIN_23)
    
    // 新增的控制引脚 (需要你在 Pin Planner 里分配给实验箱的按键和拨码开关)
    input  wire        rst_n,        // 复位按键 (低电平有效)
    input  wire        key_start,    // 启动按键 (按下为低电平触发)
    input  wire        sw_rec_play,  // 状态切换拨码：1=采集(Record)，0=回放(Play)
    input  wire        sw_loop,      // 循环切换拨码：1=循环(Loop)，0=单次(Single)

    // ADC (TLC5510) 接口 (保留原有分配，无需修改)
    input  wire [7:0]  ad_data,
    output wire        ad_clk,
    output wire        ad_oe,

    // DAC (MS9714) 接口 (保留原有分配，无需修改)
    output wire [11:0] da_data,
    output wire        da_clk
);

    // 硬件时钟与使能直连
    assign ad_clk = clk;
    assign da_clk = clk;
    assign ad_oe  = 1'b0;

    // =========================================================
    // 1. 采样率控制 (将 12MHz 降维到约 100kHz 的采样滴答)
    // =========================================================
    reg [6:0] div_cnt;
    wire sample_tick = (div_cnt == 7'd119); // 每 120 个时钟周期触发一次
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)             div_cnt <= 7'd0;
        else if(sample_tick)   div_cnt <= 7'd0;
        else                   div_cnt <= div_cnt + 1'b1;
    end

    // =========================================================
    // 2. 按键消抖与下降沿检测 (识别启动按键被按下的瞬间)
    // =========================================================
    reg [1:0] start_edge;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) start_edge <= 2'b11;
        else       start_edge <= {start_edge[0], key_start};
    end
    wire start_trigger = (start_edge == 2'b10); // 捕捉 1 变 0 的瞬间

    // =========================================================
    // 3. 核心状态机 (FSM)
    // =========================================================
    localparam IDLE   = 2'd0; // 空闲状态
    localparam RECORD = 2'd1; // 采集状态
    localparam PLAY   = 2'd2; // 回放状态
    localparam DONE   = 2'd3; // 单次完成停滞状态

    reg [1:0] current_state, next_state;

    // 状态转移同步逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= IDLE;
        else        current_state <= next_state;
    end

    // 地址计数器 (4096深度)
    reg [11:0] addr_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_cnt <= 12'd0;
        end else if (current_state == IDLE || current_state == DONE) begin
            addr_cnt <= 12'd0; // 停止时地址归零，准备下一次
        end else if ((current_state == RECORD || current_state == PLAY) && sample_tick) begin
            addr_cnt <= addr_cnt + 1'b1; // 在采集或回放状态下，跟着 tick 累加地址
        end
    end

    // 状态转移组合逻辑
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (start_trigger) begin
                    if (sw_rec_play) next_state = RECORD; // 根据开关决定去录音还是播音
                    else             next_state = PLAY;
                end
            end
            RECORD: begin
                if (addr_cnt == 12'd4095 && sample_tick) begin
                    if (sw_loop) next_state = RECORD; // 循环：地址溢出后继续录
                    else         next_state = DONE;   // 单次：录满 4096 个点就结束
                end
            end
            PLAY: begin
                if (addr_cnt == 12'd4095 && sample_tick) begin
                    if (sw_loop) next_state = PLAY;   // 循环：循环播放 RAM 内的数据
                    else         next_state = DONE;   // 单次：播完一遍就结束
                end
            end
            DONE: begin
                if (start_trigger) begin
                    if (sw_rec_play) next_state = RECORD;
                    else             next_state = PLAY;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    // =========================================================
    // 4. RAM 实例化与受控读写
    // =========================================================
    reg [7:0] ram_block [0:4095];
    reg [7:0] ram_read_data;
    
    // 只有在 RECORD 状态且到了采样节拍时，才往 RAM 里写数据
    wire we = (current_state == RECORD) && sample_tick; 

    always @(posedge clk) begin
        if (we) begin
            ram_block[addr_cnt] <= ad_data;
        end
        // 同步读出
        ram_read_data <= ram_block[addr_cnt];
    end

    // =========================================================
    // 5. DAC 智能数据分发与强制复位清零
    // =========================================================
    // 数据选择逻辑：处于“回放”输出 RAM，否则输出 AD 直通数据
    wire [7:0] da_mux = (current_state == PLAY) ? ram_read_data : ad_data;

    // 核心修改点：
    // 当 rst_n 为低电平 (0) 时，强行将 DA 输出总线全部置 0 (12'd0)
    // 当 rst_n 为高电平 (1) 时，正常输出组合好的 12 位数据
    assign da_data = (!rst_n) ? 12'b0000_0000_0000 : {da_mux, 4'b0000};

endmodule