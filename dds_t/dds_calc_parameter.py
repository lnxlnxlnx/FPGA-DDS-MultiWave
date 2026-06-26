def calculate_dds(clk_hz, N, fword):
    """
    DDS 输出频率计算
    :param clk_hz:  系统时钟频率 (Hz)
    :param N:       相位累加器位宽
    :param fword:   频率控制字
    :return: 分辨率, 输出频率, 最大输出频率
    """
    f_resolution = clk_hz / (2 ** N)    # 频率分辨率
    f_out = fword * f_resolution        # 实际输出频率
    f_max = clk_hz / 2                  # 理论最大输出频率（奈奎斯特）
    
    return f_resolution, f_out, f_max

# ====================== 你只需要改这里 ======================
CLK = 12_000_000    # 你的时钟：12MHz
N   = 21            # 你的相位累加器位宽
FWORD = 57347 - (1<<13)         # 你的频率控制字
# ===========================================================

# 计算
res, fout, fmax = calculate_dds(CLK, N, FWORD)

real_fout = 17.232
T = 1 / fout * 1e9 # 周期ns
T_us = T / 1e3
T_ms = T / 1e6
# 输出结果
print("=" * 50)
print(f"📌 DDS 计算结果")
print("=" * 50)
print(f"系统时钟        : {CLK/1e6:.2f} MHz")
print(f"累加器位宽 N    : {N} 位")
print(f"频率控制字 Fword: {FWORD}")
print("-" * 50)
print(f"✅ 频率分辨率    : {res:.4f} Hz")
print(f"✅ 输出频率      : {fout:.4f} hz")
print(f"✅ 周期      : {T:.4f} ns ### {T_us:.4f} us ### {T_ms:.4f} ms")
print(f"✅ 最大输出频率  : {fmax/1e3:.2f} kHz")
print("=" * 50)

print(f"相对误差: {abs(real_fout - fout)/real_fout:.4%}")