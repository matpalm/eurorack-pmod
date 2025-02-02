import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release

def bit_not(n, numbits=16):
    return (1 << numbits) - 1 - n

def signed_to_twos_comp(n, numbits=16):
    return n if n >= 0 else bit_not(-n, numbits) + 1

def twos_comp_to_signed(n, numbits=16):
    if (1 << (numbits-1) & n) > 0:
        return -int(bit_not(n, numbits) + 1)
    else:
        return n

@cocotb.test()
async def test_cal_00(dut):

    clk_256fs = Clock(dut.clk_256fs, 83, units='ns')
    clk_fs = Clock(dut.clk_fs, 83*256, units='ns')
    cocotb.start_soon(clk_256fs.start())
    cocotb.start_soon(clk_fs.start(start_high=False))

    # Simulate all jacks connected so the cal core doesn't zero them
    dut.jack.value = Force(0xFF)

    test_values = [
            23173,
            -14928,
            32000,
            -32000
    ]

    cal_mem = []
    with open("cal/cal_mem.hex", "r") as f_cal_mem:
        for line in f_cal_mem.readlines():
            if '//' in line:
                continue
            values = line.strip().split(' ')[1:]
            values = [int(x, 16) for x in values]
            cal_mem = cal_mem + values
    print(f"calibration constants: {cal_mem}")
    assert len(cal_mem) == 16


    channel = 0
    for cal_inx, cal_outx in [(dut.in0, dut.out0),
                              (dut.in1, dut.out1),
                              (dut.in2, dut.out2),
                              (dut.in3, dut.out3),
                              (dut.in4, dut.out4),
                              (dut.in5, dut.out5),
                              (dut.in6, dut.out6),
                              (dut.in7, dut.out7)]:

        for value in test_values:
            expect = ((value - cal_mem[channel*2]) *
                      cal_mem[channel*2 + 1]) >> 10
            cal_inx.value = Force(signed_to_twos_comp(value))
            if expect >  32000: expect = 32000
            if expect < -32000: expect = -32000
            print(f"ch={channel}\t{int(value):6d}\t", end="")
            await FallingEdge(dut.clk_fs)
            await RisingEdge(dut.clk_fs)
            await RisingEdge(dut.clk_fs)
            await RisingEdge(dut.clk_fs)
            output = twos_comp_to_signed(cal_outx.value)
            print(f"=>\t{int(output):6d}\t(expect={expect})")
            cal_inx.value = Release()
            assert output == expect

        channel = channel + 1
