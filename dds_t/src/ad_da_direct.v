module ad_da_direct(
    input  wire        clk,        // 12MHz
    
    // ADC (TLC5510)
    input  wire [7:0]  ad_data,    
    output wire        ad_clk,     
    output wire        ad_oe,      
    
    // DAC (MS9714)
    output wire [11:0] da_data,    
    output wire        da_clk      
);

    assign ad_clk = clk;
    assign da_clk = clk;
    assign ad_oe  = 1'b0;

    // 直接相连（移除之前的 ad_reversed 翻转逻辑）
    // 将8位AD数据放在高8位，低4位补零，保证幅度正常
    assign da_data = {ad_data, 4'b0000};

endmodule